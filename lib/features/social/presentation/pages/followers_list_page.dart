import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../data/services/follow_service.dart';
import 'chat_detail_page.dart';

class FollowersListPage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool showFollowers;
  
  const FollowersListPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.showFollowers,
  });

  @override
  State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _followService = FollowService();
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.showFollowers ? 0 : 1);
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
        title: Text(widget.userName, style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary(context),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: locale.get('followersTab')),
            Tab(text: locale.get('followingTab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersList(locale),
          _buildFollowingList(locale),
        ],
      ),
    );
  }

  Widget _buildFollowersList(LocaleProvider locale) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text(locale.get('userNotFound'), style: TextStyle(color: AppTheme.textSecondary(context))));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final followers = List<String>.from(userData['followers'] ?? []);

        if (followers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline_rounded,
            title: locale.get('noFollowersYet'),
            subtitle: locale.get('nobodyFollowsYet'),
          );
        }

        return _buildUserList(followers, locale);
      },
    );
  }

  Widget _buildFollowingList(LocaleProvider locale) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text(locale.get('userNotFound'), style: TextStyle(color: AppTheme.textSecondary(context))));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final following = List<String>.from(userData['following'] ?? []);

        if (following.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_outlined,
            title: locale.get('noFollowingYet'),
            subtitle: locale.get('notFollowingAnyone'),
          );
        }

        return _buildUserList(following, locale);
      },
    );
  }

  Widget _buildUserList(List<String> userIds, LocaleProvider locale) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                    ),
                    const SizedBox(width: 12),
                    Text(locale.get('loading'), style: TextStyle(color: AppTheme.textSecondary(context))),
                  ],
                ),
              );
            }

            if (!userSnapshot.data!.exists) return const SizedBox.shrink();

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            return _UserTile(
              userId: userId,
              name: userData['name'] ?? '',
              username: userData['username'] ?? '',
              photoUrl: userData['photoUrl'],
              isCurrentUser: userId == _currentUserId,
              currentUserId: _currentUserId,
              isLoading: _loadingStates[userId] ?? false,
              onAction: (action) => _handleFollowAction(userId, action, locale),
              onMessage: () => _startChat(userId, userData['name'] ?? '', locale),
            );
          },
        );
      },
    );
  }

  Future<void> _handleFollowAction(String userId, String action, LocaleProvider locale) async {
    setState(() => _loadingStates[userId] = true);

    try {
      if (action == 'unfollow') {
        final shouldUnfollow = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(locale.get('unfollowTitle'), style: TextStyle(color: AppTheme.textPrimary(context))),
            content: Text(locale.get('unfollowConfirm'), style: TextStyle(color: AppTheme.textSecondary(context))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.get('cancel'), style: TextStyle(color: AppTheme.textSecondary(context)))),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                child: Text(locale.get('unfollowTitle')),
              ),
            ],
          ),
        );
        if (shouldUnfollow == true) {
          await _followService.unfollowUser(userId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.get('unfollowed')), backgroundColor: AppTheme.success));
        }
      } else if (action == 'cancel') {
        await _followService.cancelFollowRequest(userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.get('requestCancelled')), backgroundColor: AppTheme.warning));
      } else if (action == 'follow') {
        await _followService.followUser(userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('followRequestSent')} 📩'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('error')}: $e'), backgroundColor: AppTheme.error));
    }

    if (mounted) setState(() => _loadingStates[userId] = false);
  }

  Future<void> _startChat(String userId, String userName, LocaleProvider locale) async {
    try {
      final conversationId = await _followService.getOrCreateConversation(userId);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: conversationId, otherUserId: userId, otherUserName: userName)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('couldNotStartChat')}: $e'), backgroundColor: AppTheme.error));
    }
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String userId, currentUserId, name, username;
  final String? photoUrl;
  final bool isCurrentUser, isLoading;
  final Function(String) onAction;
  final VoidCallback onMessage;

  const _UserTile({
    required this.userId, required this.currentUserId, required this.name, required this.username,
    this.photoUrl, required this.isCurrentUser, required this.isLoading, required this.onAction, required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        bool isFollowing = false, requestSent = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          isFollowing = (data['following'] as List?)?.contains(userId) ?? false;
          requestSent = (data['sentRequests'] as List?)?.contains(userId) ?? false;
        }

        String buttonText, action;
        Color buttonBg, buttonFg;
        IconData buttonIcon;

        if (isFollowing) {
          buttonText = locale.get('inFollowing');
          buttonBg = AppTheme.surfaceVariant(context);
          buttonFg = AppTheme.textPrimary(context);
          buttonIcon = Icons.check_rounded;
          action = 'unfollow';
        } else if (requestSent) {
          buttonText = locale.get('requested');
          buttonBg = Colors.orange.withOpacity(0.15);
          buttonFg = Colors.orange;
          buttonIcon = Icons.schedule_rounded;
          action = 'cancel';
        } else {
          buttonText = locale.get('follow');
          buttonBg = AppTheme.primary;
          buttonFg = Colors.white;
          buttonIcon = Icons.person_add_rounded;
          action = 'follow';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('@$username', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.surfaceVariant(context), borderRadius: BorderRadius.circular(20)),
                    child: Text(locale.get('you'), style: TextStyle(color: AppTheme.textSecondary(context), fontStyle: FontStyle.italic, fontSize: 12)),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFollowing) IconButton(icon: const Icon(Icons.message_outlined, color: AppTheme.primary), onPressed: onMessage),
                      SizedBox(
                        width: requestSent ? 100 : 95,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : () => onAction(action),
                          icon: isLoading ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: buttonFg)) : Icon(buttonIcon, size: 16),
                          label: Text(buttonText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(backgroundColor: buttonBg, foregroundColor: buttonFg, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
