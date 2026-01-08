import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../chat/domain/models/message_model.dart';
import '../../../../core/services/notification_service.dart';

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _notificationService = NotificationService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Bu sohbeti aktif olarak işaretle - bildirim gösterilmesin
    _notificationService.setActiveConversation(widget.conversationId);
    _chatService.markMessagesAsRead(widget.conversationId);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(widget.conversationId, text);
    
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mesaj listesi
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Henüz mesaj yok'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? Colors.blue 
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe 
                                    ? Colors.white70 
                                    : Colors.black54,
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
          
          // Mesaj gönderme alanı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Sohbetten çıkınca aktif conversation'ı temizle
    _notificationService.clearActiveConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}