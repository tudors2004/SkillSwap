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
  int _timeBalance = 0;
  double _reputation = 0.0;
  Map<String, dynamic>? _nextSession;
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

      final userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userPreferences = {};

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _timeBalance = userData['timeBalance'] ?? 0;
          _reputation = (userData['reputation'] ?? 0.0).toDouble();
        });
        userPreferences = userData['preferences'] ?? {};
      }

      final sessionsQuery = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'upcoming')
          .orderBy('scheduledDate')
          .limit(1)
          .get();

      if (sessionsQuery.docs.isNotEmpty) {
        _nextSession = sessionsQuery.docs.first.data();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return 'TBD';
  if (timestamp is Timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}"; 
  }
  return timestamp.toString();
  }
}