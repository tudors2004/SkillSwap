import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendConnectionRequest(String receiverId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('Not authenticated');

    final requestId = '${currentUserId}_$receiverId';

    await _firestore.collection('connection_requests').doc(requestId).set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('notifications').add({
      'userId': receiverId,
      'senderId': currentUserId,
      'type': 'connection_request',
      'requestId': requestId,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptConnectionRequest(String requestId, String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('Not authenticated');

    await _firestore.collection('connection_requests').doc(requestId).update({
      'status': 'accepted',
    });

    final chatId = _getChatId(senderId, currentUserId);
    await _firestore.collection('chats').doc(chatId).set({
      'users': [senderId, currentUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
    });

    await _firestore.collection('notifications').add({
      'userId': senderId,
      'senderId': currentUserId,
      'type': 'connection_accepted',
      'requestId': requestId,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineConnectionRequest(String requestId) async {
    await _firestore.collection('connection_requests').doc(requestId).update({
      'status': 'declined',
    });
  }

  Future<String?> getConnectionStatus(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    final requestId1 = '${currentUserId}_$otherUserId';
    final requestId2 = '${otherUserId}_$currentUserId';

    final doc1 = await _firestore.collection('connection_requests').doc(requestId1).get();
    if (doc1.exists) return doc1.data()?['status'];

    final doc2 = await _firestore.collection('connection_requests').doc(requestId2).get();
    if (doc2.exists) return doc2.data()?['status'];

    return null;
  }

  Stream<int> getUnreadNotificationCount() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }


  Stream<List<Map<String, dynamic>>> getNotifications() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}
