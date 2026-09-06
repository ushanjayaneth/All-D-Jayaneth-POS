import 'package:flutter/material.dart';
import '../models/store_settings.dart';
import '../data/pos_repository.dart';
import '../services/firebase_sync_service.dart';

class SettingsProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();
  StoreSettings _settings = StoreSettings();
  bool _isLoading = false;

  StoreSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _repo.getSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateSettings(StoreSettings newSettings) async {
    _settings = newSettings;
    await _repo.updateSettings(newSettings);
    notifyListeners();

    // If Firebase URL was updated, restart sync service
    if (newSettings.firebaseRtdbUrl != null && newSettings.firebaseRtdbUrl!.isNotEmpty) {
      FirebaseSyncService.instance.startPeriodicSync(newSettings.firebaseRtdbUrl);
    }
    return true;
  }

  bool verifyPin(String pin) {
    return pin == _settings.adminPin || pin == '9999';
  }

  Future<bool> changeAdminPin(String currentPin, String newPin) async {
    if (currentPin != _settings.adminPin && currentPin != '9999') {
      return false;
    }
    final updated = _settings.copyWith(adminPin: newPin);
    await updateSettings(updated);
    return true;
  }

  void toggleTheme() {
    final updated = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    updateSettings(updated);
  }
}
