import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillswap/services/notification_service.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> proposeExchange({
    required String partnerId,
    required String partnerName,
    required String initiatorSkill,
    required String partnerSkill,
    required int initiatorHours,
    required int partnerHours,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Unknown';

    final exchangeData = {
      'initiatorId': userId,
      'partnerId': partnerId,
      'initiatorName': userName,
      'partnerName': partnerName,
      'initiatorSkill': initiatorSkill,
      'partnerSkill': partnerSkill,
      'initiatorHours': initiatorHours,
      'partnerHours': partnerHours,
      'status': 'proposed',
      'scheduledDate': null,
      'initiatorRating': null,
      'partnerRating': null,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    };

    final docRef = await _firestore.collection('exchanges').add(exchangeData);

    await _sendNotification(
      userId: partnerId,
      title: 'New Exchange Proposal',
      message: '$userName proposed an exchange: $partnerHours hours of $partnerSkill for $initiatorHours hours of $initiatorSkill',
    );

    return docRef.id;
  }

  Future<void> scheduleExchange(String exchangeId, DateTime scheduledDate) async {
    await _firestore.collection('exchanges').doc(exchangeId).update({
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': 'scheduled',
    });

    final exchange = await getExchange(exchangeId);
    await _sendNotification(
      userId: exchange['partnerId'],
      title: 'Exchange Scheduled',
      message: 'Exchange scheduled for ${_formatDate(scheduledDate)}',
    );
  }

  Future<void> markExchangeCompleted(String exchangeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final exchange = await getExchange(exchangeId);

    await _firestore.collection('exchanges').doc(exchangeId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    final partnerId = exchange['initiatorId'] == userId
        ? exchange['partnerId']
        : exchange['initiatorId'];

    await _sendNotification(
      userId: partnerId,
      title: 'Exchange Completed',
      message: 'Please confirm the exchange to update time balances',
    );
  }

  Future<void> confirmExchange(String exchangeId, double rating) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final exchange = await getExchange(exchangeId);
    final isInitiator = exchange['initiatorId'] == userId;

    await _firestore.collection('exchanges').doc(exchangeId).update({
      isInitiator ? 'initiatorRating' : 'partnerRating': rating,
    });

    final exchangeDoc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = exchangeDoc.data()!;

    if (data['initiatorRating'] != null && data['partnerRating'] != null) {
      await _updateTimeBalances(exchange);
      await _updateReputations(exchange, data['initiatorRating'], data['partnerRating']);

      await _firestore.collection('exchanges').doc(exchangeId).update({
        'status': 'confirmed',
      });
    }
  }

  Future<void> _updateTimeBalances(Map<String, dynamic> exchange) async {
    final initiatorHours = exchange['initiatorHours'] as int;
    final partnerHours = exchange['partnerHours'] as int;

    await _firestore.collection('users').doc(exchange['initiatorId']).update({
      'timeBalance': FieldValue.increment(partnerHours - initiatorHours),
    });

    await _firestore.collection('users').doc(exchange['partnerId']).update({
      'timeBalance': FieldValue.increment(initiatorHours - partnerHours),
    });
  }

  Future<void> _updateReputations(Map<String, dynamic> exchange, double initiatorRating, double partnerRating) async {
    await _updateUserReputation(exchange['initiatorId'], partnerRating);
    await _updateUserReputation(exchange['partnerId'], initiatorRating);
  }

  Future<void> _updateUserReputation(String userId, double newRating) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data()!;

    final currentReputation = (data['reputation'] ?? 0.0).toDouble();
    final ratingCount = (data['ratingCount'] ?? 0) + 1;
    final newReputation = ((currentReputation * (ratingCount - 1)) + newRating) / ratingCount;

    await _firestore.collection('users').doc(userId).update({
      'reputation': newReputation,
      'ratingCount': ratingCount,
    });
  }

  Future<Map<String, dynamic>> getExchange(String exchangeId) async {
    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }

  Stream<List<Map<String, dynamic>>> getMyExchanges() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('exchanges')
        .where('initiatorId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot1) async {
      final query2 = await _firestore
          .collection('exchanges')
          .where('partnerId', isEqualTo: userId)
          .get();

      final allDocs = [...snapshot1.docs, ...query2.docs];
      return allDocs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
