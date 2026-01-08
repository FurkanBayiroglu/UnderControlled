import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../data/services/follow_service.dart';
import 'chat_detail_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _searchController = TextEditingController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _followService = FollowService();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  final Map<String, bool> _loadingStates = {};

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _searchQuery = query; _isSearching = false; });
      return;
    }
    setState(() { _isSearching = true; _searchQuery = query.toLowerCase(); });
    try {
      final usernameResults = await FirebaseFirestore.instance.collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff').limit(20).get();
      final nameResults = await FirebaseFirestore.instance.collection('users')
          .orderBy('name').startAt([query]).endAt(['$query\uf8ff']).limit(20).get();
      final Map<String, QueryDocumentSnapshot> uniqueResults = {};
      for (var doc in [...usernameResults.docs, ...nameResults.docs]) {
        if (doc.id != _currentUserId) uniqueResults[doc.id] = doc;
      }
      setState(() { _searchResults = uniqueResults.values.toList(); _isSearching = false; });
    } catch (e) {
      setState(() { _searchResults = []; _isSearching = false; });
    }
  }

  Future<void> _handleFollowAction(String userId, String action) async {
    setState(() => _loadingStates[userId] = true);
    try {
      switch (action) {
        case 'follow':
          await _followService.followUser(userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Takip isteği gönderildi! 📩'), backgroundColor: AppTheme.success),
            );
          }
          break;
        case 'unfollow':
          await _followService.unfollowUser(userId);
          break;
        case 'cancel':
          await _followService.cancelFollowRequest(userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('İstek iptal edildi'), backgroundColor: AppTheme.warning),
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _loadingStates[userId] = false);
  }

  Future<void> _startChat(String userId, String userName) async {
    try {
      final conversationId = await _followService.getOrCreateConversation(userId);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: conversationId, otherUserId: userId, otherUserName: userName)));
    } catch (e) {}
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
        title: Text(locale.get('searchUsers'), style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface(context),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                hintText: locale.get('searchHint'),
                hintStyle: TextStyle(color: AppTheme.textTertiary(context)),
                prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary(context)),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, color: AppTheme.textTertiary(context)), onPressed: () { _searchController.clear(); setState(() { _searchResults = []; _searchQuery = ''; }); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.surfaceVariant(context),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _searchQuery.length < 2
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_rounded, size: 64, color: AppTheme.textTertiary(context)),
                        const SizedBox(height: 16),
                        Text(locale.get('minChars'), style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 16)),
                      ]))
                    : _searchResults.isEmpty
                        ? Center(child: Text(locale.get('noResults'), style: TextStyle(color: AppTheme.textSecondary(context))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final userData = _searchResults[index].data() as Map<String, dynamic>;
                              final userId = _searchResults[index].id;
                              return _UserCard(
                                userId: userId,
                                userData: userData,
                                currentUserId: _currentUserId,
                                isLoading: _loadingStates[userId] ?? false,
                                onAction: (action) => _handleFollowAction(userId, action),
                                onMessage: () => _startChat(userId, userData['name'] ?? ''),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
}

class _UserCard extends StatelessWidget {
  final String userId, currentUserId;
  final Map<String, dynamic> userData;
  final bool isLoading;
  final Function(String) onAction;
  final VoidCallback onMessage;

  const _UserCard({required this.userId, required this.userData, required this.currentUserId, required this.isLoading, required this.onAction, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        bool isFollowing = false, requestSent = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final currentUserData = snapshot.data!.data() as Map<String, dynamic>;
          isFollowing = (currentUserData['following'] as List?)?.contains(userId) ?? false;
          requestSent = (currentUserData['sentRequests'] as List?)?.contains(userId) ?? false;
        }
        
        // Buton durumunu belirle
        String buttonText;
        Color buttonBg;
        Color buttonFg;
        String action;
        IconData? buttonIcon;
        
        if (isFollowing) {
          buttonText = locale.get('following');
          buttonBg = AppTheme.surfaceVariant(context);
          buttonFg = AppTheme.textPrimary(context);
          action = 'unfollow';
          buttonIcon = Icons.check_rounded;
        } else if (requestSent) {
          buttonText = locale.get('requestSent');
          buttonBg = Colors.orange.withOpacity(0.15);
          buttonFg = Colors.orange;
          action = 'cancel';
          buttonIcon = Icons.schedule_rounded;
        } else {
          buttonText = locale.get('follow');
          buttonBg = AppTheme.primary;
          buttonFg = Colors.white;
          action = 'follow';
          buttonIcon = Icons.person_add_rounded;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: userData['photoUrl'] != null ? NetworkImage(userData['photoUrl']) : null,
                  child: userData['photoUrl'] == null 
                      ? Text((userData['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(context))),
                      const SizedBox(height: 2),
                      Text('@${userData['username'] ?? ''}', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    ],
                  ),
                ),
                if (isFollowing)
                  IconButton(
                    icon: const Icon(Icons.message_outlined, color: AppTheme.primary),
                    onPressed: onMessage,
                  ),
                const SizedBox(width: 4),
                SizedBox(
                  width: requestSent ? 110 : 100,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => onAction(action),
                    icon: isLoading 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(buttonIcon, size: 16),
                    label: Text(buttonText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBg,
                      foregroundColor: buttonFg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
