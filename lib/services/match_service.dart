import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSmartMatches(
    String userId,
    Map<String, dynamic> userPrefs,
  ) async {
    try {
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('User profile not found');
        return [];
      }
      
      Map<String, dynamic> userProfile = userDoc.data()!;
      
      
      final querySnapshot = await _firestore
          .collection('users')
          .get();

      List<Map<String, dynamic>> allMatches = [];
      
      for (var doc in querySnapshot.docs) {
       
        if (doc.id == userId) continue;
        
        var matchData = doc.data();
        matchData['userId'] = doc.id;
        
       
        int score = _calculateMatchScore(userProfile, userPrefs, matchData);
        
        if (score > 0) { 
          matchData['finalScore'] = score;
          allMatches.add(matchData);
        }
      }

      
      allMatches.sort((a, b) => 
        (b['finalScore'] as int).compareTo(a['finalScore'] as int)
      );

      // Return top 5 matches
      return allMatches.take(5).toList();

    } catch (e) {
      print("Error in MatchService: $e");
      return [];
    }
  }

  int _calculateMatchScore(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> userPrefs,
    Map<String, dynamic> potentialMatch,
  ) {
    int score = 100; // Base score

    //  Gender preference (most important - hard filter)
    String? prefGender = userPrefs['gender'];
    String? matchGender = potentialMatch['gender'];
    
    if (prefGender != null && prefGender != 'Any') {
      if (matchGender == null) {
        return -1000; // Eliminate if no gender specified
      }
      if (prefGender != matchGender) {
        return -1000; // Eliminate non-matching gender
      }
      score += 50; // Bonus for matching gender
    }

    //  Age range preference
    Map<String, dynamic>? ageRange = userPrefs['ageRange'];
    if (ageRange != null && potentialMatch['dateOfBirth'] != null) {
      try {
        DateTime dob = (potentialMatch['dateOfBirth'] as Timestamp).toDate();
        int matchAge = DateTime.now().year - dob.year;
        
        int minAge = ((ageRange['min'] ?? 18) as num).toInt();
        int maxAge = ((ageRange['max'] ?? 100) as num).toInt();
        
        if (matchAge >= minAge && matchAge <= maxAge) {
          score += 30;
          
          
          int rangeMiddle = (minAge + maxAge) ~/ 2;
          int distanceFromMiddle = (matchAge - rangeMiddle).abs();
          score += (15 - (distanceFromMiddle ~/ 2)).clamp(0, 15);
        } else {
          score -= 50; 
        }
      } catch (e) {
        print('Error calculating age: $e');
      }
    }

    // Nationality preference
    String? prefNationality = userPrefs['nationality'];
    String? matchNationality = potentialMatch['nationality'];
    
    if (prefNationality != null && prefNationality.isNotEmpty) {
      if (matchNationality != null && 
          prefNationality.toLowerCase() == matchNationality.toLowerCase()) {
        score += 25;
      } else {
        score -= 15;
      }
    }

    // Religion preference
    String? prefReligion = userPrefs['religion'];
    String? matchReligion = potentialMatch['religion'];
    
    if (prefReligion != null && prefReligion.isNotEmpty) {
      if (matchReligion != null && 
          prefReligion.toLowerCase() == matchReligion.toLowerCase()) {
        score += 25;
      } else {
        score -= 15;
      }
    }

    // Location range
    double maxDistance = ((userPrefs['locationRange'] ?? 50) as num).toDouble();
    
    String? userLocation = userProfile['location'];
    var matchLocation = potentialMatch['location'];
    
    if (userLocation != null && matchLocation != null) {
      double? distance = _calculateDistance(userLocation, matchLocation);
      
      if (distance != null) {
        if (distance <= maxDistance) {
          // Closer is better - scale from 0 to 40 points
          int locationScore = ((maxDistance - distance) / maxDistance * 40).round();
          score += locationScore;
        } else {
          score -= 30; // Outside location range
        }
      }
    }

    //Profile completeness bonus
    if (potentialMatch['profilePicturePath'] != null && 
        (potentialMatch['profilePicturePath'] as String).isNotEmpty) {
      score += 10;
    }
    
    if (potentialMatch['description'] != null && 
        (potentialMatch['description'] as String).isNotEmpty) {
      score += 10;
    }

    // Skills bonus (if they have skills listed)
    if (potentialMatch['skills'] != null && 
        (potentialMatch['skills'] as List).isNotEmpty) {
      score += 5;
    }

    return score;
  }

  double? _calculateDistance(String location1, dynamic location2) {
    try {
      // Parse user location 
      List<String> parts1 = location1.split(',');
      if (parts1.length != 2) return null;
      
      double lat1 = double.parse(parts1[0].trim());
      double lon1 = double.parse(parts1[1].trim());

      double lat2, lon2;
      
      // Handle different location formats
      if (location2 is String) {
        List<String> parts2 = location2.split(',');
        if (parts2.length != 2) return null;
        
        lat2 = double.parse(parts2[0].trim());
        lon2 = double.parse(parts2[1].trim());
      } else if (location2 is GeoPoint) {
        lat2 = location2.latitude;
        lon2 = location2.longitude;
      } else {
        return null;
      }

      // Calculate distance in kilometers
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }
}