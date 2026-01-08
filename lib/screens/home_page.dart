import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/theme/app_theme.dart';
import '../core/localization/locale_provider.dart';
import '../core/services/notification_service.dart';
import '../features/home/presentation/pages/home_tab.dart';
import '../features/events/presentation/pages/room_list_page.dart';
import '../features/social/presentation/pages/chat_list_page.dart';
import '../features/social/presentation/pages/chat_detail_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final NotificationService _notificationService = NotificationService();
  
  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _followRequestSubscription;
  
  // Son mesaj ID'lerini takip et (duplicate bildirimleri önle)
  final Set<String> _processedMessageIds = {};
  DateTime? _lastNotificationTime;

  @override
  void initState() {
    super.initState();
    // Biraz gecikme ile dinlemeye başla (ilk yüklemede flood önleme)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startListeningToMessages();
        _startListeningToFollowRequests();
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _followRequestSubscription?.cancel();
    super.dispose();
  }

  // Yeni mesajları dinle
  void _startListeningToMessages() {
    _messageSubscription = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;
          
          final conversationId = change.doc.id;
          final lastMessage = data['lastMessage'] as String?;
          final lastMessageSenderId = data['lastMessageSenderId'] as String?;
          final lastMessageTime = data['lastMessageTime'] as Timestamp?;
          
          // Kendi mesajımızı gösterme
          if (lastMessageSenderId == _currentUserId) continue;
          
          // Aktif sohbetteyse gösterme
          if (!_notificationService.shouldShowNotification(conversationId)) continue;
          
          // Son 5 saniye içinde bildirim gösterdiysen atla (flood önleme)
          if (_lastNotificationTime != null) {
            final diff = DateTime.now().difference(_lastNotificationTime!);
            if (diff.inSeconds < 2) continue;
          }
          
          // Bu mesajı daha önce işlediysen atla
          final messageKey = '${conversationId}_${lastMessageTime?.millisecondsSinceEpoch}';
          if (_processedMessageIds.contains(messageKey)) continue;
          _processedMessageIds.add(messageKey);
          
          // Çok eski mesaj ID'lerini temizle (memory leak önleme)
          if (_processedMessageIds.length > 100) {
            _processedMessageIds.clear();
          }
          
          // Gönderen kullanıcı bilgisini al ve bildirim göster
          if (lastMessageSenderId != null && lastMessage != null) {
            _showMessageNotification(conversationId, lastMessageSenderId, lastMessage);
          }
        }
      }
    });
  }

  // Takip isteklerini dinle
  void _startListeningToFollowRequests() {
    int _previousRequestCount = 0;
    
    _followRequestSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      
      final followRequests = data['followRequests'] as List? ?? [];
      final currentCount = followRequests.length;
      
      // Yeni istek geldiyse bildirim göster
      if (currentCount > _previousRequestCount && _previousRequestCount > 0) {
        final newRequesterId = followRequests.last as String?;
        if (newRequesterId != null) {
          _showFollowRequestNotification(newRequesterId);
        }
      }
      
      _previousRequestCount = currentCount;
    });
  }

  // Mesaj bildirimi göster
  Future<void> _showMessageNotification(String conversationId, String senderId, String message) async {
    if (!mounted) return;
    
    try {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      
      final senderName = senderDoc.data()?['name'] ?? 'Yeni Mesaj';
      
      _lastNotificationTime = DateTime.now();
      
      if (mounted) {
        _notificationService.showTopBanner(
          context: context,
          title: senderName,
          body: message,
          type: 'message',
          onTap: () {
            // Mesajlar sekmesine geç ve sohbete git
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  conversationId: conversationId,
                  otherUserId: senderId,
                  otherUserName: senderName,
                ),
              ),
            );
          },
          onMarkAsRead: () async {
            // Mesajı okundu olarak işaretle
            try {
              await FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(conversationId)
                  .update({
                'unreadCount.$_currentUserId': 0,
              });
              print('✅ Mesaj okundu olarak işaretlendi');
            } catch (e) {
              print('❌ Okundu işaretleme hatası: $e');
            }
          },
        );
      }
    } catch (e) {
      print('Bildirim gösterme hatası: $e');
    }
  }

  // Takip isteği bildirimi göster
  Future<void> _showFollowRequestNotification(String requesterId) async {
    if (!mounted) return;
    
    try {
      final requesterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get();
      
      final requesterName = requesterDoc.data()?['name'] ?? 'Birisi';
      final locale = context.read<LocaleProvider>();
      
      if (mounted) {
        _notificationService.showTopBanner(
          context: context,
          title: locale.get('followRequests'),
          body: '$requesterName ${locale.isTurkish ? "seni takip etmek istiyor" : "wants to follow you"}',
          type: 'follow',
          onTap: () {
            // Profil sekmesine geç
            setState(() => _selectedIndex = 3);
          },
          onMarkAsRead: () {
            // Bildirim kapatıldı, işlem yapılmadı
            print('📍 Takip isteği bildirimi kapatıldı');
          },
        );
      }
    } catch (e) {
      print('Takip bildirimi hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    final List<Widget> pages = [
      const HomeTab(),
      const RoomListPage(showBackButton: false),
      const ChatListPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(top: BorderSide(color: AppTheme.border(context), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  selectedIndex: _selectedIndex,
                  activeIcon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: locale.get('home'),
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  index: 1,
                  selectedIndex: _selectedIndex,
                  activeIcon: Icons.groups_rounded,
                  inactiveIcon: Icons.groups_outlined,
                  label: locale.get('groups'),
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
                  index: 2,
                  selectedIndex: _selectedIndex,
                  activeIcon: Icons.chat_bubble_rounded,
                  inactiveIcon: Icons.chat_bubble_outline_rounded,
                  label: locale.get('messages'),
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  index: 3,
                  selectedIndex: _selectedIndex,
                  activeIcon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline_rounded,
                  label: locale.get('profile'),
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppTheme.primary : AppTheme.textTertiary(context),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary(context),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
