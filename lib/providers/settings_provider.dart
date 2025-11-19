import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _accountPrivacyKey = 'account_private';


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
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setAccountPrivacy(bool isPrivate) async {
    _isAccountPrivate = isPrivate;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accountPrivacyKey, isPrivate);
  }
}
