import 'package:flutter/material.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:skillswap/views/pages/chat_page.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ConnectionService _connectionService = ConnectionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _connectionService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('chat_list.error_loading'.tr(namedArgs: {'error': snapshot.error.toString()})));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('chat_list.no_connections'.tr()),
            );
          }

          final chats = snapshot.data!;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = (chat['users'] as List<dynamic>)
                  .firstWhere((uid) => uid != _auth.currentUser?.uid, orElse: () => '');

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(leading: const CircleAvatar(), title: Text('chat_list.loading'.tr()));
                  }

                  if (!userSnapshot.hasData) {
                    return ListTile(leading: const CircleAvatar(), title: Text('chat_list.user_not_found'.tr()));
                  }

                  final userData = userSnapshot.data!;
                  final userName = userData['name'] ?? 'chat_list.unknown_user'.tr();
                  final profilePicture = userData['profilePictureBase64'] as String?;

                  final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
                  final lastMessageText = lastMessage?['text'] ?? 'chat_list.no_messages'.tr();

                  // Timestamp logic
                  String timeString = '';
                  if (lastMessage != null && lastMessage['timestamp'] != null) {
                    final timestamp = lastMessage['timestamp'] as Timestamp;
                    timeString = _formatTimestamp(timestamp.toDate());
                  }

                  bool isUnread = false;
                  final currentUserId = _auth.currentUser?.uid;

                  if (lastMessage != null && currentUserId != null) {
                    final senderId = lastMessage['senderId'] as String?;
                    final readBy = (lastMessage['readBy'] as List?)?.cast<String>() ?? [];
                    if (senderId != currentUserId && !readBy.contains(currentUserId)) {
                      isUnread = true;
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (profilePicture != null && profilePicture.isNotEmpty)
                          ? MemoryImage(base64Decode(profilePicture)) as ImageProvider
                          : null,
                      child: (profilePicture == null || profilePicture.isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        color: isUnread
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatId: chat['id'],
                            otherUser: userData,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }
}