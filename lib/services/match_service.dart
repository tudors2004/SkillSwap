import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSmartMatches(String userId, Map<String, dynamic> userPrefs) async {
    try {
      
      final querySnapshot = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .orderBy('matchScore', descending: true)
          .limit(20) 
          .get();

      List<Map<String, dynamic>> rawMatches = querySnapshot.docs.map((doc) => doc.data()).toList();

      
      for (var match in rawMatches) {
        int bonusScore = 0;

       
        String prefGender = userPrefs['gender'] ?? 'Any';
        String matchGender = match['gender'] ?? 'Unknown';
        
        if (prefGender != 'Any') {
          if (prefGender == matchGender) {
            bonusScore += 50; // Big boost for correct gender
          } else {
             bonusScore -= 100; // Penalty for wrong gender
          }
        }

       
        Map<String, dynamic>? ageRange = userPrefs['ageRange'];
        int matchAge = match['age'] ?? 25; // Assuming match has an age field
        
        if (ageRange != null) {
          int min = ageRange['min'] ?? 18;
          int max = ageRange['max'] ?? 100;
          if (matchAge >= min && matchAge <= max) {
            bonusScore += 20; // Boost for being in age range
          }
        }

        match['finalScore'] = (match['matchScore'] ?? 0) + bonusScore;
      }

      rawMatches.sort((a, b) => (b['finalScore'] as int).compareTo(a['finalScore'] as int));

      return rawMatches.take(5).toList();

    } catch (e) {
      print("Error in MatchService: $e");
      return [];
    }
  }
}