import 'package:flutter_riverpod/flutter_riverpod.dart';







class UserSettings {
  final bool notificationsEnabled;
  final bool smsAlerts;
  final bool biometricLogin;

  UserSettings({
    this.notificationsEnabled = true,
    this.smsAlerts = false,
    this.biometricLogin = false,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? smsAlerts,
    bool? biometricLogin,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      biometricLogin: biometricLogin ?? this.biometricLogin,
    );
  }
}

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  UserSettingsNotifier() : super(UserSettings());

  void updateSettings(UserSettings settings) {
    state = settings;
  }
  
  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleSmsAlerts(bool value) {
    state = state.copyWith(smsAlerts: value);
  }

  void toggleBiometricLogin(bool value) {
    state = state.copyWith(biometricLogin: value);
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  return UserSettingsNotifier();
});
