import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';

// Embed edilebilir RoomChat widget'ı (room_detail_page için)
class RoomChat extends StatefulWidget {
  final String roomId;
  final bool isActive;
  final bool isMember;

  const RoomChat({
    super.key,
    required this.roomId,
    this.isActive = true,
    this.isMember = true,
  });

  @override
  State<RoomChat> createState() => _RoomChatState();
}

class _RoomChatState extends State<RoomChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (!widget.isActive || !widget.isMember) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').add({
        'text': text,
        'senderId': _currentUserId,
        'senderName': userData['name'] ?? 'Anonim',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = AppTheme.isDark(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Üye değilse sohbeti gösterme
    if (!widget.isMember) {
      return Container(
        color: AppTheme.background(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, size: 56, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                locale.get('chatLocked'),
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  locale.get('joinToSeeMessages'),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: AppTheme.background(context),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          locale.get('noMessages'),
                          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locale.get('sendFirstMessage'),
                          style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? AppTheme.primary 
                              : isDark 
                                  ? const Color(0xFF2A2A2A) 
                                  : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  data['senderName'] ?? 'Anonim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe 
                                    ? Colors.white 
                                    : AppTheme.textPrimary(context),
                                fontSize: 15,
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
          if (widget.isActive)
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 10,
                bottom: bottomPadding > 0 ? bottomPadding : 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                border: Border(top: BorderSide(color: AppTheme.border(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                        decoration: InputDecoration(
                          hintText: locale.get('sendMessage'),
                          hintStyle: TextStyle(color: AppTheme.textTertiary(context)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottomPadding > 0 ? bottomPadding + 16 : 16,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                border: Border(top: BorderSide(color: AppTheme.border(context))),
              ),
              child: Center(
                child: Text(
                  locale.get('roomNotActive'),
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
