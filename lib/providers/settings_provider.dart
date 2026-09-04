import 'package:flutter/material.dart';
import '../models/store_settings.dart';
import '../data/pos_repository.dart';

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
    return true;
  }

  void toggleTheme() {
    final updated = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    updateSettings(updated);
  }
}
