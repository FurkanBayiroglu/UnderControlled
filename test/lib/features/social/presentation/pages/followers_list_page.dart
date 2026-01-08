import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showFollowers ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Takipçiler'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersList(),
          _buildFollowingList(),
        ],
      ),
    );
  }

  Widget _buildFollowersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Kullanıcı bulunamadı'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final followers = List<String>.from(userData['followers'] ?? []);

        if (followers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Henüz takipçi yok',
            subtitle: 'Bu kullanıcıyı henüz kimse takip etmiyor',
          );
        }

        return _buildUserList(followers);
      },
    );
  }

  Widget _buildFollowingList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Kullanıcı bulunamadı'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final following = List<String>.from(userData['following'] ?? []);

        if (following.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_outlined,
            title: 'Henüz kimse takip edilmiyor',
            subtitle: 'Bu kullanıcı henüz kimseyi takip etmiyor',
          );
        }

        return _buildUserList(following);
      },
    );
  }

  Widget _buildUserList(List<String> userIds) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const ListTile(
                leading: CircleAvatar(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                title: Text('Yükleniyor...'),
              );
            }

            if (!userSnapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final name = userData['name'] ?? 'İsimsiz';
            final username = userData['username'] ?? '';
            final isCurrentUser = userId == _currentUserId;

            return _buildUserTile(
              userId: userId,
              name: name,
              username: username,
              isCurrentUser: isCurrentUser,
            );
          },
        );
      },
    );
  }

  Widget _buildUserTile({
    required String userId,
    required String name,
    required String username,
    required bool isCurrentUser,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        bool isFollowing = false;
        bool requestSent = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final currentUserData = snapshot.data!.data() as Map<String, dynamic>;
          final following = List<String>.from(currentUserData['following'] ?? []);
          final sentRequests = List<String>.from(currentUserData['sentRequests'] ?? []);
          
          isFollowing = following.contains(userId);
          requestSent = sentRequests.contains(userId);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '@$username',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: isCurrentUser
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Sen',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFollowing)
                        IconButton(
                          icon: const Icon(Icons.message_outlined),
                          color: Colors.blue,
                          onPressed: () => _startChat(userId, name),
                        ),
                      _buildFollowButton(
                        userId: userId,
                        isFollowing: isFollowing,
                        requestSent: requestSent,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFollowButton({
    required String userId,
    required bool isFollowing,
    required bool requestSent,
  }) {
    return SizedBox(
      width: 90,
      height: 32,
      child: ElevatedButton(
        onPressed: requestSent
            ? null
            : () => _handleFollowAction(userId, isFollowing),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing
              ? Colors.grey[200]
              : requestSent
                  ? Colors.orange[100]
                  : Colors.blue,
          foregroundColor: isFollowing
              ? Colors.black
              : requestSent
                  ? Colors.orange[900]
                  : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isFollowing
                  ? Colors.grey[300]!
                  : requestSent
                      ? Colors.orange[300]!
                      : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          isFollowing
              ? 'Takipte'
              : requestSent
                  ? 'İstendi'
                  : 'Takip Et',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFollowAction(String userId, bool isFollowing) async {
  // Takipten çıkma için onay iste
  if (isFollowing) {
    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Takipten Çık'),
        content: const Text('Bu kişiyi takipten çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Takipten Çık'),
          ),
        ],
      ),
    );
    
    if (shouldUnfollow != true) return;
  }
  
  try {
    if (isFollowing) {
      // Takipten çık
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'followers': FieldValue.arrayRemove([_currentUserId]),
      });
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
        'following': FieldValue.arrayRemove([userId]),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takipten çıkıldı'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      // Takip et - önce gizli hesap mı kontrol et
      final targetUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final isPrivate = targetUser.data()?['isPrivate'] ?? false;
      
      if (isPrivate) {
        // Gizli hesap - takip isteği gönder
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'followRequests': FieldValue.arrayUnion([_currentUserId]),
        });
        await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
          'sentRequests': FieldValue.arrayUnion([userId]),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Takip isteği gönderildi'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Açık hesap - direkt takip et
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'followers': FieldValue.arrayUnion([_currentUserId]),
        });
        await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
          'following': FieldValue.arrayUnion([userId]),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Takip edildi'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _startChat(String userId, String userName) async {
    try {
      // Mevcut konuşmayı ara
      final query = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUserId)
          .get();

      String? conversationId;
      
      for (var doc in query.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(userId) && participants.length == 2) {
          conversationId = doc.id;
          break;
        }
      }

      // Yoksa yeni oluştur
      if (conversationId == null) {
        final newConversation = await FirebaseFirestore.instance
            .collection('conversations')
            .add({
          'participants': [_currentUserId, userId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        conversationId = newConversation.id;
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              conversationId: conversationId!,
              otherUserId: userId,
              otherUserName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}