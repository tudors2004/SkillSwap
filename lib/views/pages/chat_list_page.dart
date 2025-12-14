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
    final theme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _connectionService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildPageWithHeader(
              theme,
              0,
              Center(child: Text('chat_list.error_loading'.tr(namedArgs: {'error': snapshot.error.toString()}))),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPageWithHeader(
              theme,
              0,
              const Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          final chats = snapshot.data!;

          return _buildPageWithHeader(
            theme,
            chats.length,
            ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                      return _buildChatTile(
                        theme: theme,
                        profilePicture: null,
                        userName: 'chat_list.loading'.tr(),
                        lastMessage: '',
                        timeString: '',
                        isUnread: false,
                        onTap: () {},
                      );
                    }

                    if (!userSnapshot.hasData) {
                      return _buildChatTile(
                        theme: theme,
                        profilePicture: null,
                        userName: 'chat_list.user_not_found'.tr(),
                        lastMessage: '',
                        timeString: '',
                        isUnread: false,
                        onTap: () {},
                      );
                    }

                    final userData = userSnapshot.data!;
                    final userName = userData['name'] ?? 'chat_list.unknown_user'.tr();
                    final profilePicture = userData['profilePictureBase64'] as String?;

                    final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
                    final lastMessageText = lastMessage?['text'] ?? 'chat_list.no_messages'.tr();

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

                    return _buildChatTile(
                      theme: theme,
                      profilePicture: profilePicture,
                      userName: userName,
                      lastMessage: lastMessageText,
                      timeString: timeString,
                      isUnread: isUnread,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageWithHeader(ThemeData theme, int chatCount, Widget content) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'chat_list.title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (chatCount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$chatCount ${chatCount == 1 ? 'conversation' : 'conversations'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'chat_list.title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Empty state content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    size: 60,
                    color: theme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'chat_list.no_connections'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required ThemeData theme,
    required String? profilePicture,
    required String userName,
    required String lastMessage,
    required String timeString,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnread
                          ? theme.primaryColor
                          : theme.primaryColor.withValues(alpha: 0.2),
                      width: isUnread ? 2 : 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: (profilePicture != null && profilePicture.isNotEmpty)
                        ? MemoryImage(base64Decode(profilePicture))
                        : null,
                    child: (profilePicture == null || profilePicture.isEmpty)
                        ? Icon(Icons.person, color: theme.primaryColor, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeString.isNotEmpty)
                            Text(
                              timeString,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                color: isUnread
                                    ? theme.primaryColor
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                color: isUnread
                                    ? theme.colorScheme.onSurface
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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