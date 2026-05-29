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

  Future<void> _clearCache(int patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_bookings_$patientId');
    } catch (_) {}
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

    // Bug Fix 1: Immediately remove the cancelled booking from the UI
    // so the user sees instant feedback without waiting for the network.
    final currentList = state.value ?? [];
    final optimisticList = currentList.where((b) => b.bookingId != bookingId).toList();
    state = AsyncValue.data(optimisticList);

    // Bug Fix 2: Clear the stale cache BEFORE fetching fresh data.
    // Without this, the next app launch re-loads the old cancelled booking
    // from SharedPreferences, making it appear to come back from the dead.
    await _clearCache(arg);

    // Now hit the backend API to actually cancel it.
    try {
      await client.cancelBooking(bookingId);
    } catch (_) {
      // If the API call fails, restore the original list so the UI is consistent.
      state = AsyncValue.data(currentList);
      rethrow;
    }

    // Finally, fetch fresh confirmed bookings from the server and save to cache.
    try {
      final fresh = await _fetchDirect(arg);
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Keep the optimistic state if the refresh network call fails.
      // The cache is already cleared so next load will fetch fresh data.
    }
  }
}

final bookingsProvider = AsyncNotifierProvider.autoDispose.family<BookingsNotifier, List<BookingDetail>, int>(() {
  return BookingsNotifier();
});
