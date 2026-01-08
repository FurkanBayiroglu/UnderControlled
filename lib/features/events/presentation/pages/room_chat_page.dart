import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../social/data/services/follow_service.dart';
import '../../../social/presentation/pages/chat_detail_page.dart';

class RoomChatPage extends StatefulWidget {
  final String roomId, roomName;
  final String? category;
  const RoomChatPage({super.key, required this.roomId, required this.roomName, this.category});

  @override
  State<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends State<RoomChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _followService = FollowService();

  static const Map<String, Color> categoryColors = {'sports': Color(0xFF10B981), 'gaming': Color(0xFF3B82F6), 'music': Color(0xFF8B5CF6), 'study': Color(0xFFF59E0B), 'chat': Color(0xFF06B6D4), 'movie': Color(0xFFEF4444), 'food': Color(0xFFF97316), 'tech': Color(0xFF6366F1), 'art': Color(0xFFEC4899)};

  Color get _categoryColor => categoryColors[widget.category] ?? AppTheme.primary;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').add({
      'text': text, 'senderId': _currentUserId, 'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({'lastMessage': text, 'lastMessageTime': FieldValue.serverTimestamp()});
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: const BorderRadius.vertical(top: const Radius.circular(24))),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppTheme.border(context), borderRadius: BorderRadius.circular(2))),
              Text(context.read<LocaleProvider>().get('participants'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final roomData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final members = List<String>.from(roomData['members'] ?? []);
                    final creatorId = roomData['createdBy'];
                    
                    // Debug log
                    print('🏠 Oda: ${widget.roomName}');
                    print('   Toplam üye: ${members.length}');
                    print('   İlk 3 üye ID: ${members.take(3).join(", ")}');
                    
                    // Boş veya null user ID'leri filtrele
                    final validMembers = members.where((id) => id != null && id.isNotEmpty).toList();
                    
                    print('   Geçerli üye: ${validMembers.length}');
                    
                    if (validMembers.isEmpty) {
                      return Center(
                        child: Text(
                          'Bu odada henüz kimse yok',
                          style: TextStyle(color: AppTheme.textSecondary(context)),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: controller,
                      itemCount: validMembers.length,
                      itemBuilder: (context, index) => _ParticipantTile(
                        userId: validMembers[index], 
                        isAdmin: validMembers[index] == creatorId, 
                        onTap: () => _showUserProfile(validMembers[index])
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserProfile(String userId) {
    // Güvenlik kontrolleri
    if (userId.isEmpty || userId == _currentUserId) return;
    
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserProfileSheet(userId: userId, followService: _followService, onMessage: () async {
        Navigator.pop(ctx);
        final conversationId = await _followService.getOrCreateConversation(userId);
        if (mounted) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          final userName = (userDoc.data()?['name'] ?? '') as String;
          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: conversationId, otherUserId: userId, otherUserName: userName)));
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary(context)), onPressed: () => Navigator.pop(context)),
        title: Text(widget.roomName, style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(Icons.people_rounded, color: _categoryColor), onPressed: _showParticipants)],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').orderBy('timestamp', descending: true).limit(100).snapshots(),
              builder: (context, snapshot) {
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) return Center(child: Text(locale.get('noMessages'), style: TextStyle(color: AppTheme.textSecondary(context))));
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    return RepaintBoundary(
                      child: _MessageBubble(text: data['text'] ?? '', isMe: isMe, senderId: data['senderId'], categoryColor: _categoryColor),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.surface(context), border: Border(top: BorderSide(color: AppTheme.border(context)))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: locale.get('sendMessage'),
                      hintStyle: TextStyle(color: AppTheme.textTertiary(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [_categoryColor.withOpacity(0.8), _categoryColor]), shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _messageController.dispose(); _scrollController.dispose(); super.dispose(); }
}

class _MessageBubble extends StatelessWidget {
  final String text, senderId;
  final bool isMe;
  final Color categoryColor;
  const _MessageBubble({required this.text, required this.isMe, required this.senderId, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      // Kendi mesajım - sağda göster
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [categoryColor.withOpacity(0.8), categoryColor]),
            borderRadius: const BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(4),
            ),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ),
      );
    }

    // Başkasının mesajı - sol tarafta avatar ve isim ile göster
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 50),
      child: FutureBuilder<DocumentSnapshot>(
        future: senderId.isNotEmpty 
            ? FirebaseFirestore.instance.collection('users').doc(senderId).get()
            : Future.value(null),
        builder: (context, snapshot) {
          String senderName = 'Kullanıcı';
          String? photoUrl;
          
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            senderName = userData['name'] ?? userData['username'] ?? 'Kullanıcı';
            photoUrl = userData['photoUrl'] as String?;
          }
          
          final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              _buildAvatar(photoUrl, initial),
              const SizedBox(width: 8),
              // İsim ve Mesaj
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gönderen ismi
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    // Mesaj balonu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: const Radius.circular(4),
                          topRight: const Radius.circular(18),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: const Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        text, 
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String initial) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 18,
          backgroundColor: categoryColor.withOpacity(0.15),
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 18,
          backgroundColor: categoryColor.withOpacity(0.15),
          child: Text(initial, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: categoryColor)),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: 18,
          backgroundColor: categoryColor.withOpacity(0.15),
          child: Text(initial, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: categoryColor)),
        ),
        memCacheWidth: 72,
        memCacheHeight: 72,
      );
    }
    
    return CircleAvatar(
      radius: 18,
      backgroundColor: categoryColor.withOpacity(0.15),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: categoryColor,
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String userId;
  final bool isAdmin;
  final VoidCallback onTap;
  const _ParticipantTile({required this.userId, required this.isAdmin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Boş userId kontrolü
    if (userId.isEmpty) {
      print('⚠️ Boş userId, atlanıyor');
      return const SizedBox.shrink();
    }
    
    print('👤 Kullanıcı yükleniyor: $userId');
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        // Hata kontrolü
        if (snapshot.hasError) {
          print('❌ Kullanıcı verisi çekme hatası: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        
        // Loading state
        if (!snapshot.hasData) {
          return ListTile(
            leading: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Loading...', style: TextStyle(color: AppTheme.textSecondary(context))),
          );
        }
        
        // Kullanıcı bulunamadı
        if (!snapshot.data!.exists) {
          print('⚠️ Kullanıcı Firestore\'da bulunamadı: $userId');
          return ListTile(
            leading: const Icon(Icons.person_off, color: Colors.grey),
            title: Text('Kullanıcı bulunamadı ($userId)', style: TextStyle(color: AppTheme.textSecondary(context))),
          );
        }
        
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = userData['name'] ?? 'User';
        final photoUrl = userData['photoUrl'] as String?;
        
        print('✓ Kullanıcı yüklendi: $name');
        
        return ListTile(
          leading: UserAvatar(photoUrl: photoUrl, name: name),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          subtitle: Text('@${userData['username'] ?? ''}', style: TextStyle(color: AppTheme.textSecondary(context))),
          trailing: isAdmin ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(8)
            ), 
            child: const Text('Admin', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))
          ) : null,
          onTap: onTap,
        );
      },
    );
  }
}

class _UserProfileSheet extends StatelessWidget {
  final String userId;
  final FollowService followService;
  final VoidCallback onMessage;
  const _UserProfileSheet({required this.userId, required this.followService, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Boş userId kontrolü
    if (userId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('User not found'),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: const BorderRadius.vertical(top: const Radius.circular(24))),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          // Hata kontrolü
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          // Loading
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Kullanıcı bulunamadı
          if (!snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }
          
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = userData['name'] ?? 'User';
          final photoUrl = userData['photoUrl'] as String?;
          final followers = (userData['followers'] as List?)?.length ?? 0;
          final following = (userData['following'] as List?)?.length ?? 0;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(photoUrl: photoUrl, name: name, radius: 40),
              const SizedBox(height: 16),
              Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
              Text('@${userData['username'] ?? ''}', style: TextStyle(color: AppTheme.textSecondary(context))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$followers ${locale.get('followers')}', style: TextStyle(color: AppTheme.textSecondary(context))),
                  const SizedBox(width: 24),
                  Text('$following ${locale.get('following')}', style: TextStyle(color: AppTheme.textSecondary(context))),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                builder: (context, snap) {
                  final isFollowing = ((snap.data?.data() as Map<String, dynamic>?)?['following'] as List?)?.contains(userId) ?? false;
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async { if (isFollowing) await followService.unfollowUser(userId); else await followService.followUser(userId); },
                          icon: Icon(isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded),
                          label: Text(isFollowing ? locale.get('unfollow') : locale.get('follow')),
                          style: ElevatedButton.styleFrom(backgroundColor: isFollowing ? AppTheme.surfaceVariant(context) : AppTheme.primary, foregroundColor: isFollowing ? AppTheme.textPrimary(context) : Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onMessage,
                          icon: const Icon(Icons.message_rounded),
                          label: Text(locale.get('message')),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}