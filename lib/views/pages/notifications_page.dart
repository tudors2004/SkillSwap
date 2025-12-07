import 'package:flutter/material.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:skillswap/services/exchange_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ConnectionService _connectionService = ConnectionService();
  final ExchangeService _exchangeService = ExchangeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications_page.title'.tr()),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _connectionService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('notifications_page.error_loading'.tr(namedArgs: {'error': snapshot.error.toString()})));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('notifications_page.no_notifications'.tr()),
            );
          }

          final notifications = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final notification in notifications) {
              final type = notification['type'] as String?;
              if (type == 'connection_accepted' && !(notification['read'] as bool)) {
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
    final type = notification['type'] as String? ?? '';
    final isRead = notification['read'] as bool? ?? false;
    final senderId = notification['senderId']?.toString() ?? '';

    if (senderId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(      future: _getUserData(senderId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('notifications_page.loading_notification'.tr()));
        }

        if (!userSnapshot.hasData) {
          return ListTile(title: Text('notifications_page.could_not_load_user'.tr()));
        }

        final userData = userSnapshot.data!;
        final userName = userData['name'] ?? 'notifications_page.someone'.tr();
        final profilePicture = userData['profilePictureBase64'] as String?;

        final titleText = notification['message'] ?? 'notifications_page.new_notification'.tr();

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
            title: Text(titleText, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
            subtitle: Text(_formatTimestamp(notification['timestamp'])),
            trailing: _buildTrailingWidget(notification, senderId),
            onTap: () => _handleNotificationTap(notification),
          ),
        );
      },
    );
  }

  Widget? _buildTrailingWidget(Map<String, dynamic> notification, String senderId) {
    final type = notification['type'] as String;

    switch (type) {
      case 'connection_request':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _acceptConnection(notification, senderId)),
            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _declineConnection(notification)),
          ],
        );
      case 'exchange_completion':
        return ElevatedButton(onPressed: () => _confirmExchange(notification), child: Text('notifications_page.confirm'.tr()));
      default:
        return null;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;

    if (!isRead) {
      _connectionService.markNotificationAsRead(notification['id']);
    }
  }

  void _acceptConnection(Map<String, dynamic> notification, String senderId) async {
    await _connectionService.acceptConnectionRequest(notification['requestId'], senderId);
    await _connectionService.deleteNotification(notification['id']);
  }

  void _declineConnection(Map<String, dynamic> notification) async {
    await _connectionService.declineConnectionRequest(notification['requestId']);
    await _connectionService.deleteNotification(notification['id']);
  }

  void _confirmExchange(Map<String, dynamic> notification) async {
    await _exchangeService.markExchangeCompleted(notification['exchangeId']);
    await _connectionService.deleteNotification(notification['id']);
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'notifications_page.just_now'.tr();
    final DateTime dateTime = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'notifications_page.just_now'.tr();
    if (difference.inHours < 1) return 'notifications_page.minutes_ago'.tr(namedArgs: {'minutes': difference.inMinutes.toString()});
    if (difference.inDays < 1) return 'notifications_page.hours_ago'.tr(namedArgs: {'hours': difference.inHours.toString()});
    return 'notifications_page.days_ago'.tr(namedArgs: {'days': difference.inDays.toString()});
  }
}
