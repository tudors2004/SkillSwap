import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _settingsKey = 'user_settings';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> saveSettings({
    String? language,
    bool? notificationsEnabled,
    bool? isAccountPrivate,
    String? themeMode,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Prepare settings data - store all values
    final settingsData = {
      'language': language ?? 'en',
      'notificationsEnabled': notificationsEnabled ?? true,
      'isAccountPrivate': isAccountPrivate ?? false,
      'themeMode': themeMode ?? 'system',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save to Firestore directly in users document
    await _firestore.collection('users').doc(_userId).set(
      {'settings': settingsData},
      SetOptions(merge: true),
    );

    // Also cache locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settingsData.toString());
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    if (_userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      return data?['settings'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error loading settings: $e');
      return null;
    }
  }

  Stream<Map<String, dynamic>?> watchSettings() {
    if (_userId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['settings'] as Map<String, dynamic>?;
    });
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    if (_userId == null) throw Exception('User not authenticated');

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(_userId).set(
      {'settings': updates},
      SetOptions(merge: true),
    );
  }

  
}
