import 'package:flutter/material.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ConnectionService _connectionService = ConnectionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _connectionService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final isRead = notification['read'] as bool;
    final senderId = notification['senderId'] as String;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(senderId),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final userName = userData?['name'] ?? 'Someone';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: isRead ? null : Colors.blue.withOpacity(0.1),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(
              type == 'connection_request'
                  ? '$userName sent you a connection request'
                  : '$userName accepted your connection request',
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(_formatTimestamp(notification['timestamp'])),
            trailing: type == 'connection_request'
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    await _connectionService.acceptConnectionRequest(
                      notification['requestId'],
                      senderId,
                    );
                    await _connectionService.markNotificationAsRead(
                      notification['id'],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await _connectionService.declineConnectionRequest(
                      notification['requestId'],
                    );
                    await _connectionService.markNotificationAsRead(
                      notification['id'],
                    );
                  },
                ),
              ],
            )
                : null,
            onTap: () async {
              if (!isRead) {
                await _connectionService.markNotificationAsRead(
                  notification['id'],
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return doc.data();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final DateTime dateTime = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
