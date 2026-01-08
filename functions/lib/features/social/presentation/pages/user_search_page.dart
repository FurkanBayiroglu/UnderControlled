import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    setState(() => _isSearching = true);
    
    try {
      final results = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: _currentUserId)
          .limit(20)
          .get();
      
      setState(() {
        _searchResults = results.docs;
        _isSearching = false;
      });
    } catch (e) {
      print('İlk yükleme hatası: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _loadInitialUsers();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.toLowerCase();
    });

    try {
      final usernameResults = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .limit(20)
          .get();

      final nameResults = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(20)
          .get();

      final Map<String, QueryDocumentSnapshot> uniqueResults = {};
      
      for (var doc in [...usernameResults.docs, ...nameResults.docs]) {
        if (doc.id != _currentUserId) {
          uniqueResults[doc.id] = doc;
        }
      }

      setState(() {
        _searchResults = uniqueResults.values.toList();
        _isSearching = false;
      });
    } catch (e) {
      print('Arama hatası: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // TAKİP İSTEĞİ GÖNDER
  Future<void> _handleFollowAction(String userId, bool isFollowing, bool requestSent) async {
    setState(() => _loadingStates[userId] = true);
    
    try {
      if (isFollowing) {
        // Takipten çık
        await _followService.unfollowUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Takipten çıkıldı'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else if (requestSent) {
        // İsteği iptal et
        await _followService.cancelFollowRequest(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İstek iptal edildi'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Yeni istek gönder
        await _followService.sendFollowRequest(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Takip isteği gönderildi ✓'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
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
    } finally {
      if (mounted) {
        setState(() => _loadingStates[userId] = false);
      }
    }
  }

  // Mesaj başlat
  Future<void> _startChat(String userId, String userName) async {
    try {
      final conversationId = await _followService.getOrCreateConversation(userId);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              conversationId: conversationId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kullanıcı Ara'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Arama Alanı
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı veya isim ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadInitialUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          
          // Sonuçlar
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aramak için kullanıcı adı yazın'
                                  : 'Sonuç bulunamadı',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final userData = _searchResults[index].data() as Map<String, dynamic>;
                          final userId = _searchResults[index].id;
                          final isLoading = _loadingStates[userId] ?? false;
                          
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: Text(
                                      (userData['name'] ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    userData['name'] ?? 'İsimsiz',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '@${userData['username'] ?? ''}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Mesaj butonu (sadece takip edilenler için)
                                      if (isFollowing)
                                        IconButton(
                                          icon: const Icon(Icons.message_outlined),
                                          color: Colors.blue,
                                          onPressed: () => _startChat(
                                            userId,
                                            userData['name'] ?? 'İsimsiz',
                                          ),
                                        ),
                                      // Takip/İstek butonu
                                      SizedBox(
                                        width: 110,
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () => _handleFollowAction(userId, isFollowing, requestSent),
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
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      isFollowing
                                                          ? Icons.person_remove
                                                          : requestSent
                                                              ? Icons.hourglass_top
                                                              : Icons.person_add,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        isFollowing
                                                            ? 'Takipte'
                                                            : requestSent
                                                                ? 'Bekliyor'
                                                                : 'Takip Et',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}