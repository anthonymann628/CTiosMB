// lib/services/settings_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  bool vibrateOnScan = true;
  bool keepScreenOn = false;
  bool useMaps = true;
  bool useSpeech = true;
  String selectedLanguage = 'English';

  /// Load all settings from SharedPreferences.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    vibrateOnScan = prefs.getBool('vibrateOnScan') ?? true;
    keepScreenOn = prefs.getBool('keepScreenOn') ?? false;
    useMaps = prefs.getBool('useMaps') ?? true;
    useSpeech = prefs.getBool('useSpeech') ?? true;
    selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';

    notifyListeners();
  }

  /// Internal method to save all current fields to SharedPreferences.
  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrateOnScan', vibrateOnScan);
    await prefs.setBool('keepScreenOn', keepScreenOn);
    await prefs.setBool('useMaps', useMaps);
    await prefs.setBool('useSpeech', useSpeech);
    await prefs.setString('selectedLanguage', selectedLanguage);
  }

  /// Each setting has a setter that updates the field and re-saves everything.
  void setVibrateOnScan(bool value) {
    vibrateOnScan = value;
    _saveAll();
    notifyListeners();
  }

  void setKeepScreenOn(bool value) {
    keepScreenOn = value;
    _saveAll();
    notifyListeners();
  }

  void setUseMaps(bool value) {
    useMaps = value;
    _saveAll();
    notifyListeners();
  }

  void setUseSpeech(bool value) {
    useSpeech = value;
    _saveAll();
    notifyListeners();
  }

  void setSelectedLanguage(String lang) {
    selectedLanguage = lang;
    _saveAll();
    notifyListeners();
  }
}
