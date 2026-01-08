import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ← YENİ EKLENEN
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../social/data/services/follow_service.dart';
import '../../../social/presentation/pages/chat_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FollowService _followService = FollowService();
  bool _isClearing = false; // Loading state

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
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          locale.get('notifications'),
          style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700),
        ),
        actions: [
          _isClearing
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(locale.get('markAllRead'), style: const TextStyle(color: AppTheme.primary)),
                ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary(context),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: locale.get('all')),
            Tab(text: locale.get('followRequests')),
            Tab(text: locale.get('messages')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(locale),
          _buildFollowRequestsTab(locale),
          _buildMessagesTab(locale),
        ],
      ),
    );
  }

  // ============ TÜMÜNÜ OKUNDU İŞARETLE (GÜNCELLENMİŞ) ============
  Future<void> _markAllAsRead() async {
    if (_isClearing) return;
    
    setState(() => _isClearing = true);
    
    try {
      // Firebase Cloud Function'ı çağır - bu badge'i de temizler!
      final callable = FirebaseFunctions.instance.httpsCallable('clearAllNotifications');
      final result = await callable.call();
      
      final clearedCount = result.data['clearedCount'] ?? 0;
      print('✅ $clearedCount bildirim temizlendi');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LocaleProvider>().get('allMarkedRead')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Cloud Function hatası: $e');
      
      // Fallback: Lokal olarak temizle
      await _markAllAsReadLocally();
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  // Fallback metodu - Cloud Function çalışmazsa
  Future<void> _markAllAsReadLocally() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Badge sayısını sıfırla
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(_currentUserId),
        {
          'badgeCount': 0,
          'unreadNotificationCount': 0,
        },
      );
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LocaleProvider>().get('allMarkedRead')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Lokal temizleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // Tüm Bildirimler
  Widget _buildAllTab(LocaleProvider locale) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          debugPrint('❌ User snapshot error: ${userSnapshot.error}');
        }
        
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final followRequests = List<String>.from(userData?['followRequests'] ?? []);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('toUserId', isEqualTo: _currentUserId)
              .limit(100)
              .snapshots(),
          builder: (context, notifSnapshot) {
            if (notifSnapshot.hasError) {
              debugPrint('❌ Notifications error: ${notifSnapshot.error}');
            }
            
            if (notifSnapshot.connectionState == ConnectionState.waiting && followRequests.isEmpty) {
              return Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            
            final notifications = notifSnapshot.data?.docs ?? [];
            final sortedNotifications = List<QueryDocumentSnapshot>.from(notifications);
            sortedNotifications.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['timestamp'] as Timestamp?;
              final bTime = bData['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });
            
            final limitedNotifications = sortedNotifications.take(50).toList();
            
            if (followRequests.isEmpty && limitedNotifications.isEmpty) {
              return _buildEmptyState(locale.get('noNotifications'), Icons.notifications_off_rounded);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (followRequests.isNotEmpty) ...[
                  _SectionHeader(title: locale.get('followRequests'), count: followRequests.length),
                  ...followRequests.map((userId) => _FollowRequestCard(
                    userId: userId,
                    onAccept: () => _acceptFollowRequest(userId),
                    onReject: () => _rejectFollowRequest(userId),
                  )),
                  const SizedBox(height: 16),
                ],
                
                if (limitedNotifications.isNotEmpty) ...[
                  _SectionHeader(title: locale.get('recentActivity'), count: limitedNotifications.length),
                  ...limitedNotifications.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _NotificationCard(
                      notificationId: doc.id,
                      data: data,
                      onTap: () => _handleNotificationTap(doc.id, data),
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // Takip İstekleri Tab
  Widget _buildFollowRequestsTab(LocaleProvider locale) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _followService.getFollowRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(locale.get('noFollowRequests'), Icons.person_add_disabled_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final user = requests[index];
            return _FollowRequestDetailCard(
              user: user,
              onAccept: () => _acceptFollowRequest(user['id']),
              onReject: () => _rejectFollowRequest(user['id']),
            );
          },
        );
      },
    );
  }

  // Mesaj Tab
  Widget _buildMessagesTab(LocaleProvider locale) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final conversations = snapshot.data?.docs ?? [];
        
        final unreadConversations = conversations.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
          return unreadCount != null && (unreadCount[_currentUserId] ?? 0) > 0;
        }).toList();

        if (unreadConversations.isEmpty) {
          return _buildEmptyState(locale.get('noUnreadMessages'), Icons.mark_email_read_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: unreadConversations.length,
          itemBuilder: (context, index) {
            final doc = unreadConversations[index];
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != _currentUserId, orElse: () => '');
            final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[_currentUserId] ?? 0;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                final userName = userData?['name'] ?? 'User';

                return _MessageNotificationCard(
                  conversationId: doc.id,
                  otherUserId: otherUserId,
                  userName: userName,
                  lastMessage: data['lastMessage'] ?? '',
                  unreadCount: unreadCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          conversationId: doc.id,
                          otherUserId: otherUserId,
                          otherUserName: userName,
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptFollowRequest(String userId) async {
    try {
      await _followService.acceptFollowRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LocaleProvider>().get('requestAccepted')), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _rejectFollowRequest(String userId) async {
    try {
      await _followService.rejectFollowRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LocaleProvider>().get('requestRejected')), backgroundColor: AppTheme.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(String notificationId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'isRead': true});
    
    final type = data['type'] as String?;
    switch (type) {
      case 'follow':
      case 'follow_accepted':
        break;
      case 'message':
        break;
      case 'room_invite':
        break;
    }
  }
}

// ============ WIDGET'LAR ============

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(count.toString(), style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _FollowRequestCard extends StatelessWidget {
  final String userId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FollowRequestCard({required this.userId, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? 'User';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)))),
              IconButton(icon: const Icon(Icons.check, color: AppTheme.success), onPressed: onAccept),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.error), onPressed: onReject),
            ],
          ),
        );
      },
    );
  }
}

class _FollowRequestDetailCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FollowRequestDetailCard({required this.user, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(context))),
                Text('@${user['username'] ?? ''}', style: TextStyle(color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Kabul Et', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onReject, child: const Text('Reddet')),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationCard({required this.notificationId, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? '';
    final isRead = data['isRead'] as bool? ?? false;
    final senderName = data['senderName'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;

    IconData icon;
    Color color;
    String displayMessage;

    switch (type) {
      case 'follow':
      case 'follow_request':
        icon = Icons.person_add_rounded;
        color = Colors.purple;
        displayMessage = 'seni takip etmek istiyor';
        break;
      case 'follow_accepted':
        icon = Icons.check_circle_rounded;
        color = AppTheme.success;
        displayMessage = 'takip isteğini kabul etti';
        break;
      case 'message':
        icon = Icons.message_rounded;
        color = AppTheme.primary;
        displayMessage = data['message'] ?? 'mesaj gönderdi';
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppTheme.primary;
        displayMessage = 'bildirim gönderdi';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? AppTheme.surface(context) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isRead ? AppTheme.border(context) : color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
                      children: [
                        TextSpan(text: senderName ?? 'Birisi', style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' $displayMessage'),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_formatTime(timestamp.toDate()), style: TextStyle(fontSize: 12, color: AppTheme.textTertiary(context))),
                    ),
                ],
              ),
            ),
            if (!isRead)
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) return '${time.day}/${time.month}';
    if (diff.inDays > 0) return '${diff.inDays}g önce';
    if (diff.inHours > 0) return '${diff.inHours}s önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes}d önce';
    return 'Şimdi';
  }
}

class _MessageNotificationCard extends StatelessWidget {
  final String conversationId;
  final String otherUserId;
  final String userName;
  final String lastMessage;
  final int unreadCount;
  final VoidCallback onTap;

  const _MessageNotificationCard({
    required this.conversationId,
    required this.otherUserId,
    required this.userName,
    required this.lastMessage,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', 
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(unreadCount.toString(), 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), 
                        textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 4),
                  Text(lastMessage, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}