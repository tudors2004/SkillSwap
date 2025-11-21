import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class ProfileService {
  static const String _profileSetupKey = 'profile_setup_completed';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isProfileSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final localCheck = prefs.getBool(_profileSetupKey) ?? false;

    if (localCheck) return true;

    // Check Firestore if local storage doesn't have it
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (!doc.exists) {
          // Create initial document for new users
          await _firestore.collection('users').doc(userId).set({
            'userId': userId,
            'email': _auth.currentUser?.email,
            'profileSetupCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return false;
        }

        final isCompleted = doc.data()?['profileSetupCompleted'] ?? false;

        if (isCompleted) {
          await prefs.setBool(_profileSetupKey, true);
        }

        return isCompleted;
      } catch (e) {
        print('Error checking profile setup: $e');
        return false;
      }
    }

    return false;
  }

  Future<void> markProfileSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileSetupKey, true);

    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      // Use set with merge instead of update
      await _firestore.collection('users').doc(userId).set({
        'profileSetupCompleted': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<String?> convertImageToBase64(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Check file size (Firestore has 1MB limit per document)
      if (bytes.length > 500000) { // 500KB limit for safety
        throw Exception('Image too large. Please choose a smaller image.');
      }

      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image: $e');
      rethrow;
    }
  }

  Future<void> saveProfile({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required String nationality,
    required String phoneNumber,
    String? profilePicturePath,
    String? location,
    List<String>? skills,
    Map<String, dynamic>? preferences,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Convert profile picture to base64 if provided
    String? profilePictureBase64;
    if (profilePicturePath != null) {
      profilePictureBase64 = await convertImageToBase64(profilePicturePath);
    }

    // Parse location if provided
    GeoPoint? geoPoint;
    if (location != null) {
      final coords = location.split(',');
      if (coords.length == 2) {
        geoPoint = GeoPoint(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
      }
    }

    // Prepare profile data
    final profileData = {
      'userId': userId,
      'email': _auth.currentUser?.email,
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'nationality': nationality,
      'phoneNumber': phoneNumber,
      'profilePictureBase64': profilePictureBase64,
      'location': geoPoint,
      'skills': skills ?? [],
      'preferences': preferences ?? {},
      'profileSetupCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save to Firestore
    await _firestore.collection('users').doc(userId).set(
      profileData,
      SetOptions(merge: true),
    );

    // Mark as completed locally
    await markProfileSetupCompleted();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(userId).set(
      updates,
      SetOptions(merge: true),
    );
  }

  Future<void> deleteProfilePicture() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'profilePictureBase64': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting profile picture: $e');
    }
  }
}
