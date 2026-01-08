import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../../rooms/presentation/pages/room_detail_page.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.chat),
              text: 'Sohbetler',
            ),
            Tab(
              icon: Icon(Icons.groups),
              text: 'Oda Sohbetleri',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsTab(),
          _buildRoomChatsTab(),
        ],
      ),
    );
  }

  // 1. SEKME: Özel Sohbetler (DM)
  Widget _buildConversationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var conversations = snapshot.data?.docs ?? [];
        
        // Manuel sıralama - lastMessageTime'a göre
        conversations.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final aTime = aData['lastMessageTime'] as Timestamp?;
          final bTime = bData['lastMessageTime'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime);
        });

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Henüz sohbetiniz yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kullanıcı arayarak sohbet başlatabilirsiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversationDoc = conversations[index];
            final conversation = conversationDoc.data() as Map<String, dynamic>;
            final conversationId = conversationDoc.id;
            final participants = List<String>.from(conversation['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return const SizedBox();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    leading: CircleAvatar(),
                    title: Text('Yükleniyor...'),
                  );
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) return const SizedBox();

                final lastMessage = conversation['lastMessage'] ?? 'Mesaj yok';
                final lastMessageTime = conversation['lastMessageTime'] as Timestamp?;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      userData['name']?[0]?.toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    userData['name'] ?? 'İsimsiz',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    _formatTime(lastMessageTime?.toDate()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          conversationId: conversationId,
                          otherUserId: otherUserId,
                          otherUserName: userData['name'] ?? 'İsimsiz',
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
    );
  }

  // 2. SEKME: Oda Sohbetleri
  Widget _buildRoomChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('participants', arrayContains: _currentUserId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Veriler yüklenemedi',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final rooms = snapshot.data?.docs ?? [];

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Katıldığınız aktif oda yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Odalar sekmesinden bir odaya katılın',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final roomDoc = rooms[index];
            final roomData = roomDoc.data() as Map<String, dynamic>;
            final room = RoomModel.fromFirestore(roomDoc);

            return _buildRoomChatTile(room, roomData);
          },
        );
      },
    );
  }

  Widget _buildRoomChatTile(RoomModel room, Map<String, dynamic> roomData) {
  final categoryColor = _getCategoryColor(room.category);
  final categoryIcon = _getCategoryIcon(room.category);
  final participantCount = roomData['participantCount'] ?? 0; // BU SATIRI EKLE

  return StreamBuilder<QuerySnapshot>(
    // Son mesajı al
    stream: FirebaseFirestore.instance
        .collection('rooms')
        .doc(room.id)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots(),
    builder: (context, messageSnapshot) {
      String lastMessage = 'Henüz mesaj yok';
      DateTime? lastMessageTime;

      if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
        final lastMsgData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        final senderName = lastMsgData['senderName'] ?? 'Birisi';
        final text = lastMsgData['text'] ?? '';
        lastMessage = '$senderName: $text';
        lastMessageTime = (lastMsgData['timestamp'] as Timestamp?)?.toDate();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Katılımcı sayısı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$participantCount', // DEĞİŞTİRİLDİ
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              // Etkinlik zamanı
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: room.isOngoing ? Colors.green : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room.isOngoing
                        ? 'Devam ediyor'
                        : _formatEventDate(room.eventDateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: room.isOngoing ? Colors.green : Colors.grey[500],
                      fontWeight: room.isOngoing ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessageTime != null)
                Text(
                  _formatTime(lastMessageTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomDetailPage(roomId: room.id),
              ),
            );
          },
        ),
      );
    },
  );
}
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'Şimdi';
    }
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Tarih belirtilmedi';
    
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      return 'Geçmiş';
    } else if (difference.inDays == 0) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yarın ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'sports': return Colors.green;
      case 'music': return Colors.purple;
      case 'gaming': return Colors.blue;
      case 'study': return Colors.orange;
      case 'chat': return Colors.teal;
      case 'movie': return Colors.red;
      case 'food': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'sports': return Icons.sports_soccer;
      case 'music': return Icons.music_note;
      case 'gaming': return Icons.gamepad;
      case 'study': return Icons.school;
      case 'chat': return Icons.chat;
      case 'movie': return Icons.movie;
      case 'food': return Icons.restaurant;
      default: return Icons.group;
    }
  }
}