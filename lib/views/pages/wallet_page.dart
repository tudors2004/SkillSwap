import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/exchange_service.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ExchangeService _exchangeService = ExchangeService();

  int _hoursLearned = 0;
  int _hoursTaught = 0;
  double _reputation = 0.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _connections = [];

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
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _hoursLearned = userData['hoursLearned'] ?? 0;
          _hoursTaught = userData['hoursTaught'] ?? 0;
          _reputation = (userData['reputation'] ?? 0.0).toDouble();
        });
      }
      _connections = [];

      final sentRequests = await _firestore
          .collection('connection_requests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final receivedRequests = await _firestore
          .collection('connection_requests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in sentRequests.docs) {
        final data = doc.data();
        final otherUserId = data['receiverId'];
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();

        if (otherUserDoc.exists) {
          _connections.add({
            'id': otherUserId,
            'name': otherUserDoc.data()!['name'] ?? 'Unknown',
            'skills': otherUserDoc.data()!['skills'] ?? [],
            'profilePictureBase64': otherUserDoc.data()!['profilePictureBase64'],
          });
        }
      }
      for (var doc in receivedRequests.docs) {
        final data = doc.data();
        final otherUserId = data['senderId'];
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();

        if (otherUserDoc.exists) {
          _connections.add({
            'id': otherUserId,
            'name': otherUserDoc.data()!['name'] ?? 'Unknown',
            'skills': otherUserDoc.data()!['skills'] ?? [],
            'profilePictureBase64': otherUserDoc.data()!['profilePictureBase64'],
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
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
      return const Center(child: CircularProgressIndicator());
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
              _buildBalanceCard(),
              const SizedBox(height: 24),
              _buildConnectionsSection(),
              const SizedBox(height: 24),
              _buildExchangesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8C4D8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    'Hours Learned',
                    style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_hoursLearned',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Hours Taught',
                    style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_hoursTaught',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 20, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                'Reputation: ${_reputation.toStringAsFixed(1)}/5.0',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Connections',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_connections.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No connections yet. Start connecting with people!'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _connections.length,
            itemBuilder: (context, index) {
              final connection = _connections[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(connection['name'][0].toUpperCase()),
                  ),
                  title: Text(connection['name']),
                  subtitle: Text(
                    'Skills: ${(connection['skills'] as List).take(2).join(', ')}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showExchangeProposalDialog(connection),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildExchangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Exchanges',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _exchangeService.getMyExchanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final exchanges = snapshot.data!;
            if (exchanges.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No exchanges yet'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exchanges.length,
              itemBuilder: (context, index) {
                return _buildExchangeCard(exchanges[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildExchangeCard(Map<String, dynamic> exchange) {
    final userId = _auth.currentUser!.uid;
    final isInitiator = exchange['initiatorId'] == userId;
    final partnerName = isInitiator ? exchange['partnerName'] : exchange['initiatorName'];
    final mySkill = isInitiator ? exchange['initiatorSkill'] : exchange['partnerSkill'];
    final partnerSkill = isInitiator ? exchange['partnerSkill'] : exchange['initiatorSkill'];
    final myHours = isInitiator ? exchange['initiatorHours'] : exchange['partnerHours'];
    final partnerHours = isInitiator ? exchange['partnerHours'] : exchange['initiatorHours'];
    final status = exchange['status'] ?? 'proposed';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'proposed':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.event;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showExchangeDetailsDialog(exchange),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (exchange['scheduledDate'] != null)
                    Text(
                      DateFormat('MMM dd, HH:mm').format(
                        (exchange['scheduledDate'] as Timestamp).toDate(),
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Exchange with $partnerName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text('I give: $myHours hours of $mySkill'),
              Text('I receive: $partnerHours hours of $partnerSkill'),
            ],
          ),
        ),
      ),
    );
  }

  void _showExchangeProposalDialog(Map<String, dynamic> connection) {
    final initiatorSkillController = TextEditingController();
    final partnerSkillController = TextEditingController();
    final initiatorHoursController = TextEditingController(text: '1');
    final partnerHoursController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Propose Exchange with ${connection['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('I want to learn:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(connection['id'])
                    .collection('skills')
                    .doc('userSkills')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('Partner has no skills added');
                  }

                  final skillsData = snapshot.data!.data() as Map<String, dynamic>;
                  final skillsToOffer = (skillsData['skillsToOffer'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                  if (skillsToOffer.isEmpty) {
                    return const Text('Partner has no skills to offer');
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: 'Select skill to learn',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: skillsToOffer.map((skill) {
                      final skillName = skill['name'] as String;
                      return DropdownMenuItem(
                        value: skillName,
                        child: Text(skillName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      partnerSkillController.text = value ?? '';
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: partnerHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours requested',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('In exchange for:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('skills')
                    .doc('userSkills')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('You have no skills added. Please add skills first.');
                  }

                  final skillsData = snapshot.data!.data() as Map<String, dynamic>;
                  final mySkills = (skillsData['skillsToOffer'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                  if (mySkills.isEmpty) {
                    return const Text('You have no skills to offer. Please add skills first.');
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: 'Select skill to offer',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: mySkills.map((skill) {
                      final skillName = skill['name'] as String;
                      return DropdownMenuItem(
                        value: skillName,
                        child: Text(skillName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      initiatorSkillController.text = value ?? '';
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: initiatorHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours offered',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (initiatorSkillController.text.isEmpty || partnerSkillController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select both skills')),
                );
                return;
              }

              try {
                await _exchangeService.proposeExchange(
                  partnerId: connection['id'],
                  partnerName: connection['name'],
                  initiatorSkill: initiatorSkillController.text,
                  partnerSkill: partnerSkillController.text,
                  initiatorHours: int.parse(initiatorHoursController.text),
                  partnerHours: int.parse(partnerHoursController.text),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exchange proposal sent!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Propose'),
          ),
        ],
      ),
    );
  }

  void _showExchangeDetailsDialog(Map<String, dynamic> exchange) {
    final userId = _auth.currentUser!.uid;
    final isInitiator = exchange['initiatorId'] == userId;
    final partnerName = isInitiator ? exchange['partnerName'] : exchange['initiatorName'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exchange with $partnerName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExchangeDetail(
                'I agreed to ${isInitiator ? 'help' : 'receive help from'} $partnerName',
              ),
              const SizedBox(height: 12),
              _buildExchangeDetail(
                'Teaching: ${isInitiator ? exchange['initiatorSkill'] : exchange['partnerSkill']}',
              ),
              _buildExchangeDetail(
                'Duration: ${isInitiator ? exchange['initiatorHours'] : exchange['partnerHours']} hours',
              ),
              const Divider(height: 24),
              _buildExchangeDetail(
                'In exchange for: ${isInitiator ? exchange['partnerSkill'] : exchange['initiatorSkill']}',
              ),
              _buildExchangeDetail(
                'Duration: ${isInitiator ? exchange['partnerHours'] : exchange['initiatorHours']} hours',
              ),
              const Divider(height: 24),
              _buildExchangeDetail(
                'Status: ${exchange['status'].toString().toUpperCase()}',
                bold: true,
              ),
              if (exchange['scheduledDate'] != null)
                _buildExchangeDetail(
                  'Scheduled: ${DateFormat('EEEE, MMM dd, yyyy \'at\' HH:mm').format((exchange['scheduledDate'] as Timestamp).toDate())}',
                ),
            ],
          ),
        ),
        actions: _buildExchangeActions(exchange, isInitiator),
      ),
    );
  }

  Widget _buildExchangeDetail(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  List<Widget> _buildExchangeActions(Map<String, dynamic> exchange, bool isInitiator) {
    final actions = <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ];

    final status = exchange['status'] ?? 'proposed';

    switch (status) {
      case 'proposed':
        if (isInitiator) {
          actions.add(
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showScheduleDialog(exchange);
              },
              child: const Text('Schedule'),
            ),
          );
        }
        break;

      case 'scheduled':
        actions.add(
          ElevatedButton(
            onPressed: () async {
              await _exchangeService.markExchangeCompleted(exchange['id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as completed. Waiting for confirmation.')),
                );
              }
            },
            child: const Text('Mark Complete'),
          ),
        );
        break;

      case 'completed':
        final hasRated = isInitiator
            ? exchange['initiatorRating'] != null
            : exchange['partnerRating'] != null;
        if (!hasRated) {
          actions.add(
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showRatingDialog(exchange);
              },
              child: const Text('Confirm & Rate'),
            ),
          );
        }
        break;
    }

    return actions;
  }

  void _showScheduleDialog(Map<String, dynamic> exchange) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Exchange'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final scheduledDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                await _exchangeService.scheduleExchange(exchange['id'], scheduledDateTime);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exchange scheduled!')),
                  );
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(Map<String, dynamic> exchange) {
    double rating = 3.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => rating = index + 1.0);
                    },
                  );
                }),
              ),
              Text('${rating.toInt()}/5', style: const TextStyle(fontSize: 18)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _exchangeService.confirmExchange(exchange['id'], rating);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exchange confirmed! Time balance updated.')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
