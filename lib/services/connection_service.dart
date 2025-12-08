import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;
  String? get currentUserId => _currentUser?.uid;

  Future<void> sendConnectionRequest(String receiverId) async {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) throw Exception('Not authenticated');

    final requestId = '${currentUserId}_$receiverId';

    await _firestore.collection('connection_requests').doc(requestId).set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sendNotification(
      userId: receiverId,
      type: 'connection_request',
      title: 'New Connection Request',
      message: 'You received a connection request.',
      requestId: requestId,
    );
  }

  Future<void> acceptConnectionRequest(String requestId, String senderId) async {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) throw Exception('Not authenticated');

    print('DEBUG: Accepting request - requestId: $requestId, senderId: $senderId, currentUserId: $currentUserId');

    try {
      // Check if document exists
      final docSnapshot = await _firestore.collection('connection_requests').doc(requestId).get();
      print('DEBUG: Document exists: ${docSnapshot.exists}');
      print('DEBUG: Document data: ${docSnapshot.data()}');

      await _firestore.collection('connection_requests').doc(requestId).update({
        'status': 'accepted',
      });
      print('DEBUG: Status updated successfully');

      final chatId = _getChatId(senderId, currentUserId);
      print('DEBUG: Creating chat with ID: $chatId');

      await _firestore.collection('chats').doc(chatId).set({
        'users': [senderId, currentUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
      print('DEBUG: Chat created successfully');

      await _sendNotification(
        userId: senderId,
        type: 'connection_accepted',
        title: 'Connection Accepted',
        message: 'Your connection request was accepted.',
      );
      print('DEBUG: Notification sent successfully');
    } catch (e, stackTrace) {
      print('DEBUG: Error in acceptConnectionRequest: $e');
      print('DEBUG: Stack trace: $stackTrace');
      rethrow;
    }
  }


  Future<void> declineConnectionRequest(String requestId) async {
    await _firestore.collection('connection_requests').doc(requestId).update({
      'status': 'declined',
    });
  }

  Stream<List<Map<String, dynamic>>> getChats() {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

      Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) throw Exception('Not authenticated');

    final message = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': {
        'senderId': currentUserId,
        'text': text,
        'readBy': [currentUserId],
        'timestamp': FieldValue.serverTimestamp(),
      },
    });
  }

    Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

    Future<void> markMessageAsRead(String chatId) async {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return;

    final docRef = _firestore.collection('chats').doc(chatId);
    final doc = await docRef.get();
    final lastMessage = doc.data()?['lastMessage'] as Map<String, dynamic>?;

    if (lastMessage != null && lastMessage['senderId'] != currentUserId) {
      final readBy = (lastMessage['readBy'] as List?)?.cast<String>() ?? [];
      if (!readBy.contains(currentUserId)) {
        await docRef.update({
          'lastMessage.readBy': FieldValue.arrayUnion([currentUserId])
        });
      }
    }
  }

  Future<String?> getConnectionStatus(String otherUserId) async {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return null;

    final requestId1 = '${currentUserId}_$otherUserId';
    final requestId2 = '${otherUserId}_$currentUserId';

    final doc1 =
    await _firestore.collection('connection_requests').doc(requestId1).get();
    if (doc1.exists) return doc1.data()?['status'];

    final doc2 =
    await _firestore.collection('connection_requests').doc(requestId2).get();
    if (doc2.exists) return doc2.data()?['status'];

    return null;
  }

  Stream<int> getUnreadNotificationCount() {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Map<String, dynamic>>> getNotifications() {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> _sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? requestId,
    String? exchangeId,
  }) async {
    final currentUserId = _currentUser?.uid;

    final notificationData = {
      'userId': userId,
      'senderId': currentUserId,
      'type': type,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (requestId != null) {
      notificationData['requestId'] = requestId;
    }

    if (exchangeId != null) {
      notificationData['exchangeId'] = exchangeId;
    }

    await _firestore.collection('notifications').add(notificationData);
  }

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}

