import 'package:flutter/material.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:skillswap/views/pages/chat_page.dart';

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
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You have no connections yet.'),
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

              return FutureBuilder<Map<String, dynamic>?>(                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(leading: CircleAvatar(), title: Text('Loading...'));
                  }

                  if (!userSnapshot.hasData) {
                    return const ListTile(leading: CircleAvatar(), title: Text('User not found'));
                  }

                  final userData = userSnapshot.data!;
                  final userName = userData['name'] ?? 'Unknown User';
                  final profilePicture = userData['profilePictureBase64'] as String?;

                  final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
                  final lastMessageText = lastMessage?['text'] ?? 'No messages yet';
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
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        color: isUnread
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
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
}
