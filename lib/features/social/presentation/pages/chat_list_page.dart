import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../shared/widgets/user_avatar.dart';
import 'chat_detail_page.dart';
import '../../../events/presentation/pages/room_chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar - Başlık yerine direkt tab'lar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary(context),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: [
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(locale.get('conversations')),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.groups_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(locale.get('groupChats')),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(locale.get('contacts')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationsTab(locale),
                  _buildGroupChatsTab(locale),
                  _buildContactsTab(locale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsTab(LocaleProvider locale) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('conversations').where('participants', arrayContains: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        var conversations = snapshot.data?.docs ?? [];
        conversations.sort((a, b) {
          final aTime = (a.data() as Map)['lastMessageTime'] as Timestamp?;
          final bTime = (b.data() as Map)['lastMessageTime'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        if (conversations.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.primary)),
            const SizedBox(height: 20),
            Text(locale.get('noConversations'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(locale.get('startChat')),
            ),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            final doc = conversations[index];
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
            final lastMessage = data['lastMessage'] as String? ?? '';
            final lastTime = data['lastMessageTime'] as Timestamp?;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? '';
                final photoUrl = userData['photoUrl'] as String?;
                if (name.isEmpty) return const SizedBox();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: UserAvatar(photoUrl: photoUrl, name: name, radius: 28),
                    title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                    subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary(context))),
                    trailing: Text(_formatTime(lastTime?.toDate()), style: TextStyle(fontSize: 12, color: AppTheme.textTertiary(context))),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: doc.id, otherUserId: otherUserId, otherUserName: name, otherUserPhotoUrl: photoUrl))),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupChatsTab(LocaleProvider locale) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').where('participants', arrayContains: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        var rooms = snapshot.data?.docs ?? [];
        rooms.sort((a, b) {
          final aTime = (a.data() as Map)['lastMessageTime'] as Timestamp?;
          final bTime = (b.data() as Map)['lastMessageTime'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        if (rooms.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.groups_rounded, size: 48, color: Color(0xFF8B5CF6))),
            const SizedBox(height: 20),
            Text(locale.get('noGroupChats'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/groups'),
              icon: const Icon(Icons.explore_rounded),
              label: Text(locale.get('exploreGroups')),
            ),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            final doc = rooms[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final category = data['category'] ?? 'chat';
            final lastMessage = data['lastMessage'] ?? '';
            final participantCount = (data['participants'] as List?)?.length ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [_getCategoryColor(category).withOpacity(0.8), _getCategoryColor(category)]), borderRadius: BorderRadius.circular(16)),
                  child: Icon(_getCategoryIcon(category), color: Colors.white, size: 28),
                ),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                subtitle: Row(children: [
                  Text(lastMessage.isNotEmpty ? lastMessage : '$participantCount ${locale.get('people')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary(context))),
                ]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomChatPage(roomId: doc.id, roomName: name, category: category))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactsTab(LocaleProvider locale) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final following = List<String>.from(userData['following'] ?? []);
        if (following.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFFF59E0B))),
            const SizedBox(height: 20),
            Text(locale.get('noContacts'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: following.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            final userId = following[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnap) {
                final contactData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                final name = contactData['name'] ?? '';
                final username = contactData['username'] ?? '';
                final photoUrl = contactData['photoUrl'] as String?;
                if (name.isEmpty) return const SizedBox();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: UserAvatar(photoUrl: photoUrl, name: name, radius: 28, textColor: const Color(0xFFF59E0B), backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1)),
                    title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                    subtitle: Text('@$username', style: TextStyle(color: AppTheme.textSecondary(context))),
                    trailing: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primary),
                    onTap: () async {
                      final conversationId = await _chatService.getOrCreateConversation(userId);
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: conversationId, otherUserId: userId, otherUserName: name, otherUserPhotoUrl: photoUrl)));
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}g';
    if (diff.inHours > 0) return '${diff.inHours}s';
    if (diff.inMinutes > 0) return '${diff.inMinutes}d';
    return 'Şimdi';
  }

  Color _getCategoryColor(String? category) {
    const colors = {'sports': Color(0xFF10B981), 'gaming': Color(0xFF3B82F6), 'music': Color(0xFF8B5CF6), 'study': Color(0xFFF59E0B), 'chat': Color(0xFF06B6D4), 'movie': Color(0xFFEF4444), 'food': Color(0xFFF97316), 'tech': Color(0xFF6366F1)};
    return colors[category] ?? const Color(0xFF6B7280);
  }

  IconData _getCategoryIcon(String? category) {
    const icons = {'sports': Icons.sports_soccer_rounded, 'gaming': Icons.sports_esports_rounded, 'music': Icons.music_note_rounded, 'study': Icons.school_rounded, 'chat': Icons.chat_bubble_rounded, 'movie': Icons.movie_rounded, 'food': Icons.restaurant_rounded, 'tech': Icons.computer_rounded};
    return icons[category] ?? Icons.group_rounded;
  }
}
