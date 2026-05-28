import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'slots_provider.dart' show apiClientProvider;

class SessionNotifier extends AsyncNotifier<UserEntity?> {
  @override
  FutureOr<UserEntity?> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_user_session');
      if (cachedJson != null) {
        return UserEntity.fromJson(jsonDecode(cachedJson));
      }
    } catch (_) {
      // Ignore cache errors
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_session');
      
      final client = ref.read(apiClientProvider);
      final user = await client.postLogin(email, password);
      await _saveSession(user);
      state = AsyncValue.data(user);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  Future<void> register(
    String name,
    String email,
    String role,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.postRegister(name, email, role, password);
      // Do not auto-login on register
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_session');
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> _saveSession(UserEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_session', jsonEncode(user.toJson()));
    } catch (_) {}
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, UserEntity?>(() {
  return SessionNotifier();
});

// A clean derivation of the selected patient ID from the active session
final selectedPatientIdProvider = Provider<int>((ref) {
  final session = ref.watch(sessionProvider).value;
  return session?.id ?? 1;
});
