import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillswap/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final SettingsService _settingsService = SettingsService();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final cloudSettings = await _settingsService.loadSettings();
    if (cloudSettings != null && cloudSettings['themeMode'] != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == cloudSettings['themeMode'],
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
    await _settingsService.saveSettings(themeMode: mode.toString());
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
  Future<void> syncFromCloud() async {
    await _loadThemeMode();
  }

  Future<void> clearData() async {
    _themeMode = ThemeMode.system;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}
