import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/available_slot.dart';
import '../models/service.dart';


// Host setup for local FastAPI backend — reads from .env at runtime with platform detection fallback
final apiClientProvider = Provider<ApiClient>((ref) {
  String defaultUrl = 'http://localhost:8000';
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid) {
        defaultUrl = 'http://10.0.2.2:8000';
      }
    } catch (_) {}
  }

  String baseUrl = defaultUrl;
  try {
    if (dotenv.isInitialized) {
      final envVal = dotenv.env['API_BASE_URL'];
      if (envVal != null && envVal.trim().isNotEmpty) {
        baseUrl = envVal.trim();
      }
    }
  } catch (_) {
    // If dotenv is not initialized or failed to load, fallback safely
  }
  return ApiClient(baseUrl: baseUrl);
});

class SlotSearchArgs {
  final int serviceId;
  final String dateStr;
  final int patientId;

  SlotSearchArgs({
    required this.serviceId,
    required this.dateStr,
    required this.patientId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotSearchArgs &&
          runtimeType == other.runtimeType &&
          serviceId == other.serviceId &&
          dateStr == other.dateStr &&
          patientId == other.patientId;

  @override
  int get hashCode =>
      serviceId.hashCode ^ dateStr.hashCode ^ patientId.hashCode;
}

final availableSlotsProvider =
    FutureProvider.autoDispose.family<List<AvailableSlot>, SlotSearchArgs>((
      ref,
      args,
    ) async {
      final client = ref.watch(apiClientProvider);
      return await client.getAvailableSlots(
        args.serviceId,
        args.dateStr,
        args.patientId,
      );
    });

// A robust cached provider to fetch services instantly (offline-first)
class ServicesNotifier extends AutoDisposeAsyncNotifier<List<Service>> {
  @override
  FutureOr<List<Service>> build() async {
    List<Service>? cachedServices;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_services');
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        cachedServices = decoded.map((item) => Service.fromJson(item)).toList();
      }
    } catch (_) {
      // Ignore cache loading errors
    }

    if (cachedServices != null && cachedServices.isNotEmpty) {
      // Fetch fresh data in background
      _fetchFreshData();
      return cachedServices;
    }

    return _fetchDirect();
  }

  Future<List<Service>> _fetchDirect() async {
    final client = ref.watch(apiClientProvider);
    final services = await client.getServices();
    _saveToCache(services);
    return services;
  }

  void _fetchFreshData() async {
    try {
      final fresh = await _fetchDirect();
      state = AsyncValue.data(fresh);
    } catch (_) {}
  }

  void _saveToCache(List<Service> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(services.map((s) => s.toJson()).toList());
      await prefs.setString('cached_services', jsonStr);
    } catch (_) {}
  }
}

final servicesProvider =
    AsyncNotifierProvider.autoDispose<ServicesNotifier, List<Service>>(() {
      return ServicesNotifier();
    });
