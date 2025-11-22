import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SkillsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  Future<void> saveSkills(Map<String, dynamic> skillsData) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _firestore.collection('users').doc(user.uid).collection('skills').doc('userSkills').set(skillsData);
  }

  Future<Map<String, dynamic>?> getSkills() async {
    final user = _currentUser;
    if (user == null) {
      return null;
    }
    final docSnapshot = await _firestore.collection('users').doc(user.uid).collection('skills').doc('userSkills').get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }
}
