import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Data variables
  int _timeBalance = 0;
  double _reputation = 0.0;
  Map<String, dynamic>? _nextSession;
  List<Map<String, dynamic>> _topMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      //  Load user's time balance and reputation
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _timeBalance = userData['timeBalance'] ?? 0;
          _reputation = (userData['reputation'] ?? 0.0).toDouble();
        });
      }

      //Load next upcoming session
      final sessionsQuery = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'upcoming')
          .orderBy('scheduledDate')
          .limit(1)
          .get();

      if (sessionsQuery.docs.isNotEmpty) {
        setState(() {
          _nextSession = sessionsQuery.docs.first.data();
        });
      }

      //  Load top matches
      final matchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .orderBy('matchScore', descending: true)
          .limit(5)
          .get();

      setState(() {
        _topMatches = matchesQuery.docs
            .map((doc) => doc.data())
            .toList();
      });

    } catch (e) {
      print('Error loading wallet data: $e');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWalletData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time Balance Card 
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C4D8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Time Balance: $_timeBalance Hours',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reputation: ${_reputation.toStringAsFixed(1)}/5',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Next Session Section (Dynamic)
              const Text(
                'Next Session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  
                ),
              ),
              const SizedBox(height: 12),
              
              if (_nextSession != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C4D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nextSession!['skillName'] ?? 'Session',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'with ${_nextSession!['partnerName'] ?? 'Partner'}, ${_formatTimestamp(_nextSession!['scheduledDate'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C4D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No upcoming sessions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),

              // Top Matches Section (Dynamic)
              const Text(
                'Top Matches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  
                ),
              ),
              const SizedBox(height: 12),

              if (_topMatches.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C4D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No matches found yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                )
              else
                ..._topMatches.map((match) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMatchCard(
                      name: match['name'] ?? 'Unknown',
                      description: match['description'] ?? '',
                      skills: List<String>.from(match['skills'] ?? []),
                      avatarColor: _getColorFromString(match['avatarColor'] ?? 'blue'),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return 'TBD';
  // If it's a Firestore Timestamp, convert to Date
  if (timestamp is Timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}"; 
  }
  return timestamp.toString();
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMatchCard({
    required String name,
    required String description,
    required List<String> skills,
    required Color avatarColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8C4D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B3A7B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 30,
            backgroundColor: avatarColor,
            child: const Icon(
              Icons.person,
              size: 35,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}