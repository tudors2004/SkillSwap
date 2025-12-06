import 'package:flutter/material.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          } 

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No new notifications'),
            );
          }

          final notifications = snapshot.data!;

          // Auto-mark 'connection_accepted' notifications as read
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final notification in notifications) {
              if (notification['type'] == 'connection_accepted' && !(notification['read'] as bool)) {
                _connectionService.markNotificationAsRead(notification['id']);
              }
            }
          });

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
    final isConnectionRequest = type == 'connection_request';

    return FutureBuilder<Map<String, dynamic>?>(      future: _getUserData(senderId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
              title: Container(
                height: 16,
                width: 150,
                color: Colors.grey.withOpacity(0.2),
              ),
              subtitle: Container(
                height: 12,
                width: 100,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          );
        }

        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const ListTile(
              leading: CircleAvatar(child: Icon(Icons.error)),
              title: Text('Could not load notification'),
              subtitle: Text('Error fetching user data'),
            ),
          );
        }

        final userData = userSnapshot.data!;
        final userName = userData['name'] ?? 'Someone';
        final profilePicture = userData['profilePictureBase64'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: isRead ? null : Theme.of(context).primaryColor.withOpacity(0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (profilePicture != null && profilePicture.isNotEmpty)
                  ? MemoryImage(base64Decode(profilePicture)) as ImageProvider
                  : null,
              child: (profilePicture == null || profilePicture.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              isConnectionRequest
                  ? '$userName sent you a connection request'
                  : '$userName accepted your connection request',
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(_formatTimestamp(notification['timestamp'])),
            trailing: isConnectionRequest
                ? _buildActionButtons(notification, senderId)
                : null,
            onTap: () async {
              if (!isRead && isConnectionRequest) {
                await _connectionService.markNotificationAsRead(notification['id']);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> notification, String senderId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () async {
            await _connectionService.acceptConnectionRequest(
              notification['requestId'],
              senderId,
            );
            await _connectionService.deleteNotification(notification['id']);
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () async {
            await _connectionService.declineConnectionRequest(notification['requestId']);
            await _connectionService.deleteNotification(notification['id']);
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
