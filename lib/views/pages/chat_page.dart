import 'dart:io'; // Import Platform
import 'package:flutter/material.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> otherUser;

  const ChatPage({super.key, required this.chatId, required this.otherUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ConnectionService _connectionService = ConnectionService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _connectionService.markMessageAsRead(widget.chatId);
  }

  /// Handle Standard Phone Call
  Future<void> _handlePhoneCall() async {
    final phoneNumber = widget.otherUser['phoneNumber'] as String?;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showSnackBar('This user does not have a phone number.');
      return;
    }

    final bool? confirm = await _showConfirmationDialog(
      title: 'Make a call',
      content: 'Do you want to call ${widget.otherUser['name']}?',
      confirmText: 'Call',
    );

    if (confirm == true) {
      _launchUri(Uri(scheme: 'tel', path: phoneNumber));
    }
  }

  /// NEW: Handle Video Call
  Future<void> _handleVideoCall() async {
    final phoneNumber = widget.otherUser['phoneNumber'] as String?;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showSnackBar('This user does not have a phone number.');
      return;
    }

    // 1. Determine action based on Platform
    String platformApp = Platform.isIOS ? 'FaceTime' : 'WhatsApp';

    // 2. Ask for permission
    final bool? confirm = await _showConfirmationDialog(
      title: 'Video Call',
      content: 'Start a video call with ${widget.otherUser['name']} using $platformApp?',
      confirmText: 'Video Call',
    );

    if (confirm == true) {
      Uri videoUri;

      if (Platform.isIOS) {
        // Try FaceTime
        videoUri = Uri(scheme: 'facetime', path: phoneNumber);
      } else {
        // Try WhatsApp for Android (Opens chat, user taps video button)
        // Note: Direct video intent isn't public API for WhatsApp,
        // but this is the closest "phone number" based link.
        videoUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
      }

      _launchUri(videoUri);
    }
  }

  Future<void> _launchUri(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (mounted) {
        // Provide a specific error message for Android users without WhatsApp
        if (!Platform.isIOS && uri.toString().contains('whatsapp')) {
          _showSnackBar('Could not launch WhatsApp. Is it installed?');
        } else {
          _showSnackBar('Could not launch app.');
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser['name'] ?? 'Chat'),
        actions: [
          // NEW: Video Call Button
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _handleVideoCall,
            tooltip: 'Video Call',
          ),
          // Existing Phone Call Button
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _handlePhoneCall,
            tooltip: 'Voice Call',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _connectionService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUserId;

                    String timeString = '';
                    if (message['timestamp'] != null) {
                      final Timestamp ts = message['timestamp'];
                      final dt = ts.toDate();
                      final hour = dt.hour.toString().padLeft(2, '0');
                      final minute = dt.minute.toString().padLeft(2, '0');
                      timeString = '$hour:$minute';
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                          border: !isMe ? Border.all(color: Colors.grey.withOpacity(0.2)) : null,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeString,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _connectionService.sendMessage(widget.chatId, _messageController.text.trim());
      _messageController.clear();
    }
  }
}