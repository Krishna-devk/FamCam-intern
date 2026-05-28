import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkout_result.dart';
import 'slots_provider.dart' show apiClientProvider;

class BookingsNotifier extends AutoDisposeFamilyAsyncNotifier<List<BookingDetail>, int> {
  @override
  FutureOr<List<BookingDetail>> build(int patientId) async {
    List<BookingDetail>? cachedBookings;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_bookings_$patientId');
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        cachedBookings = decoded.map((item) => BookingDetail.fromJson(item)).toList();
      }
    } catch (_) {
      // Ignore cache loading errors
    }

    if (cachedBookings != null && cachedBookings.isNotEmpty) {
      // Fetch fresh data in background
      _fetchFreshData(patientId);
      return cachedBookings;
    }

    return _fetchDirect(patientId);
  }

  Future<List<BookingDetail>> _fetchDirect(int patientId) async {
    final client = ref.watch(apiClientProvider);
    final bookings = await client.getBookings(patientId);
    _saveToCache(patientId, bookings);
    return bookings;
  }

  void _fetchFreshData(int patientId) async {
    try {
      final fresh = await _fetchDirect(patientId);
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Keep cached data silently if network fails
    }
  }

  void _saveToCache(int patientId, List<BookingDetail> bookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(bookings.map((b) => b.toJson()).toList());
      await prefs.setString('cached_bookings_$patientId', jsonStr);
    } catch (_) {}
  }

  Future<void> cancelBooking(int bookingId) async {
    final client = ref.watch(apiClientProvider);
    await client.cancelBooking(bookingId);
    
    // Explicit refresh
    try {
      final fresh = await _fetchDirect(arg);
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Fallback: manually update locally
      final list = state.value ?? [];
      final freshLocal = list.where((b) => b.bookingId != bookingId).toList();
      state = AsyncValue.data(freshLocal);
    }
  }
}

final bookingsProvider = AsyncNotifierProvider.autoDispose.family<BookingsNotifier, List<BookingDetail>, int>(() {
  return BookingsNotifier();
});
