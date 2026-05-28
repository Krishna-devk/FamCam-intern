import 'package:dio/dio.dart';
import '../models/service.dart';
import '../models/available_slot.dart';
import '../models/cart_item.dart';
import '../models/checkout_result.dart';
import '../models/user.dart';

import 'exceptions.dart';

class ApiClient {
  final Dio _dio;

  // Uses localhost:8000 by default for Android emulator. For local web, use localhost:8000.
  ApiClient({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? 'http://localhost:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  Future<List<Service>> getServices({String? query}) async {
    try {
      // We will define an endpoint on /services to list all seeded services in our backend
      final response = await _dio.get(
        '/services',
        queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
      );
      if (response.statusCode == 200) {
        var list = response.data as List;
        return list.map((i) => Service.fromJson(i)).toList();
      }
      throw NetworkException("Failed to load services");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error fetching services");
    }
  }

  Future<List<AvailableSlot>> getAvailableSlots(
    int serviceId,
    String dateStr,
    int patientId,
  ) async {
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
      throw NetworkException(
        e.message ?? "Network error fetching available slots",
      );
    }
  }

  Future<CheckoutResult> postCheckout(
    int patientId,
    List<CartItem> items,
  ) async {
    final payload = {
      'patient_id': patientId,
      'items': items.map((i) => i.toJson()).toList(),
    };

    try {
      final response = await _dio.post('/cart/checkout', data: payload);
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

  Future<List<BookingDetail>> getBookings(int patientId) async {
    try {
      final response = await _dio.get(
        '/bookings',
        queryParameters: {'patient_id': patientId},
      );
      if (response.statusCode == 200) {
        var list = response.data as List;
        return list.map((i) => BookingDetail.fromJson(i)).toList();
      }
      throw NetworkException("Failed to load bookings");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error fetching bookings");
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      final response = await _dio.patch('/bookings/$bookingId/cancel');
      if (response.statusCode == 200) {
        return true;
      }
      throw NetworkException("Failed to cancel booking");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error cancelling booking");
    }
  }

  Future<List<Map<String, dynamic>>> getFAQs() async {
    try {
      final response = await _dio.get('/faqs');
      if (response.statusCode == 200) {
        var list = response.data['faqs'] as List;
        return list.map((i) => Map<String, dynamic>.from(i)).toList();
      }
      throw NetworkException("Failed to load FAQs");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error fetching FAQs");
    }
  }

  Future<UserEntity> postLogin(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        return UserEntity.fromJson(response.data);
      }
      throw NetworkException("Failed to login");
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 404) {
        throw NetworkException("User not found with this email.");
      }
      if (e.response != null && e.response!.statusCode == 401) {
        throw NetworkException("Incorrect password.");
      }
      throw NetworkException(e.message ?? "Network error during login");
    }
  }

  Future<UserEntity> postRegister(
    String name,
    String email,
    String role,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'role': role,
          'password': password,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserEntity.fromJson(response.data);
      }
      throw NetworkException("Failed to register");
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        throw NetworkException("A user with this email already exists.");
      }
      throw NetworkException(e.message ?? "Network error during registration");
    }
  }

  Future<UserEntity> updateUser(int userId, String name, String email) async {
    try {
      final response = await _dio.put(
        '/auth/$userId',
        data: {'name': name, 'email': email},
      );
      if (response.statusCode == 200) {
        return UserEntity.fromJson(response.data);
      }
      throw NetworkException("Failed to update user");
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        throw NetworkException("Email already in use.");
      }
      throw NetworkException(e.message ?? "Network error updating user");
    }
  }

  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final response = await _dio.put(
        '/auth/$userId/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw NetworkException("Failed to change password");
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 401) {
        throw NetworkException("Incorrect current password.");
      }
      throw NetworkException(e.message ?? "Network error changing password");
    }
  }

  Future<bool> deleteAccount(int userId) async {
    try {
      final response = await _dio.delete('/auth/$userId');
      if (response.statusCode == 200) {
        return true;
      }
      throw NetworkException("Failed to delete account");
    } on DioException catch (e) {
      throw NetworkException(e.message ?? "Network error deleting account");
    }
  }

}
