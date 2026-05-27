import 'package:dio/dio.dart';
import '../models/service.dart';
import '../models/available_slot.dart';
import '../models/cart_item.dart';
import '../models/checkout_result.dart';
import 'exceptions.dart';

class ApiClient {
  final Dio _dio;

  // Uses localhost:8000. For Android emulator use 10.0.2.2:8000.
  // In a clean architecture, we can pass it or read from environment/settings.
  ApiClient({String? baseUrl}) 
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'http://localhost:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<List<Service>> getServices() async {
    try {
      // We will define an endpoint on /services to list all seeded services in our backend
      final response = await _dio.get('/services');
      if (response.statusCode == 200) {
        var list = response.data as List;
        return list.map((i) => Service.fromJson(i)).toList();
      }
      throw NetworkException("Failed to load services");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error fetching services");
    }
  }

  Future<List<AvailableSlot>> getAvailableSlots(int serviceId, String dateStr, int patientId) async {
    try {
      final response = await _dio.get(
        '/slots/available',
        queryParameters: {
          'service_id': serviceId,
          'date': dateStr,
          'patient_id': patientId,
        },
      );
      if (response.statusCode == 200) {
        var list = response.data['available_slots'] as List;
        return list.map((i) => AvailableSlot.fromJson(i)).toList();
      }
      throw NetworkException("Failed to load slots");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error fetching available slots");
    }
  }

  Future<CheckoutResult> postCheckout(int patientId, List<CartItem> items) async {
    final payload = {
      'patient_id': patientId,
      'items': items.map((i) => i.toJson()).toList(),
    };

    try {
      final response = await _dio.post(
        '/cart/checkout',
        data: payload,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return CheckoutSuccess.fromJson(response.data);
      }
      throw NetworkException("Server error during checkout");
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        final data = e.response!.data;
        if (data is Map && data['status'] == 'failed') {
          return CheckoutFailure.fromJson(Map<String, dynamic>.from(data));
        }
      }
      throw NetworkException(e.message ?? "Network error during checkout");
    }
  }
}
