import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillswap/services/notification_service.dart';
import 'package:skillswap/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _accountPrivacyKey = 'account_private';
  final SettingsService _settingsService = SettingsService();

  String _language = 'en';
  bool _notificationsEnabled = true;
  bool _isAccountPrivate = false;

  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isAccountPrivate => _isAccountPrivate;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cloudSettings = await _settingsService.loadSettings();
    if (cloudSettings != null) {
      _language = cloudSettings['language'] ?? 'en';
      _notificationsEnabled = cloudSettings['notificationsEnabled'] ?? true;
      _isAccountPrivate = cloudSettings['isAccountPrivate'] ?? false;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_languageKey) ?? 'en';
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _isAccountPrivate = prefs.getBool(_accountPrivacyKey) ?? false;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    await _settingsService.saveSettings(language: language);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await NotificationService().requestPermissionIfNeeded();
      bool isAllowed = await NotificationService().requestPermission();
      if (!isAllowed) {
        return;
      }
    } else {
      await NotificationService().cancelAllNotifications();
    }

    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    await _settingsService.saveSettings(notificationsEnabled: enabled);
  }

  Future<void> setAccountPrivacy(bool isPrivate) async {
    _isAccountPrivate = isPrivate;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accountPrivacyKey, isPrivate);
    await _settingsService.saveSettings(isAccountPrivate: isPrivate);
  }
  Future<void> syncFromCloud() async {
    await _loadSettings();
  }
}
