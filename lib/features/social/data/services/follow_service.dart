import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Kullanıcı arama
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    
    // Username ile ara
    final usernameResults = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('username', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .limit(20)
        .get();

    // İsim ile ara
    final nameResults = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    // Sonuçları birleştir ve tekrarları kaldır
    final Map<String, Map<String, dynamic>> uniqueResults = {};
    
    for (var doc in [...usernameResults.docs, ...nameResults.docs]) {
      if (doc.id != currentUserId) {
        uniqueResults[doc.id] = {
          'id': doc.id,
          ...doc.data(),
        };
      }
    }

    return uniqueResults.values.toList();
  }

  // Konuşma oluştur veya getir
  Future<String> getOrCreateConversation(String otherUserId) async {
    // Mevcut konuşmayı kontrol et
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    // Yeni konuşma oluştur
    final conversationRef = await _firestore.collection('conversations').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': null,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {currentUserId: 0, otherUserId: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  // Takip isteği gönder (HER ZAMAN istek olarak gider)
  Future<void> followUser(String targetUserId) async {
    final batch = _firestore.batch();

    // Hedef kullanıcının bilgilerini al
    final targetUserDoc = await _firestore
        .collection('users')
        .doc(targetUserId)
        .get();

    if (!targetUserDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    // Zaten takip ediyor mu kontrol et
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final currentUserData = currentUserDoc.data() ?? {};
    final following = List<String>.from(currentUserData['following'] ?? []);
    final sentRequests = List<String>.from(currentUserData['sentRequests'] ?? []);
    
    if (following.contains(targetUserId)) {
      throw Exception('Zaten takip ediyorsunuz');
    }
    
    if (sentRequests.contains(targetUserId)) {
      throw Exception('Zaten istek gönderildi');
    }

    // Takip isteği gönder (tüm hesaplar için)
    batch.update(
      _firestore.collection('users').doc(targetUserId),
      {
        'followRequests': FieldValue.arrayUnion([currentUserId]),
      },
    );

    batch.update(
      _firestore.collection('users').doc(currentUserId),
      {
        'sentRequests': FieldValue.arrayUnion([targetUserId]),
      },
    );

    // Bildirim oluştur
    final currentUserName = currentUserData['name'] ?? 'Birisi';
    final notificationRef = _firestore.collection('notifications').doc();
    batch.set(notificationRef, {
      'type': 'follow_request',
      'fromUserId': currentUserId,
      'toUserId': targetUserId,
      'senderName': currentUserName,
      'message': 'seni takip etmek istiyor',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  // Takibi bırak
  Future<void> unfollowUser(String targetUserId) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('users').doc(targetUserId),
      {
        'followers': FieldValue.arrayRemove([currentUserId]),
      },
    );

    batch.update(
      _firestore.collection('users').doc(currentUserId),
      {
        'following': FieldValue.arrayRemove([targetUserId]),
      },
    );

    await batch.commit();
  }

  // Takip isteğini iptal et
  Future<void> cancelFollowRequest(String targetUserId) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('users').doc(targetUserId),
      {
        'followRequests': FieldValue.arrayRemove([currentUserId]),
      },
    );

    batch.update(
      _firestore.collection('users').doc(currentUserId),
      {
        'sentRequests': FieldValue.arrayRemove([targetUserId]),
      },
    );

    await batch.commit();
  }

  // Takip isteğini kabul et
  Future<void> acceptFollowRequest(String requesterId) async {
    final batch = _firestore.batch();

    // Mevcut kullanıcı bilgilerini al
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final currentUserData = currentUserDoc.data() ?? {};
    final currentUserName = currentUserData['name'] ?? 'Birisi';

    // İsteği kaldır ve takipçi olarak ekle
    batch.update(
      _firestore.collection('users').doc(currentUserId),
      {
        'followRequests': FieldValue.arrayRemove([requesterId]),
        'followers': FieldValue.arrayUnion([requesterId]),
      },
    );

    batch.update(
      _firestore.collection('users').doc(requesterId),
      {
        'sentRequests': FieldValue.arrayRemove([currentUserId]),
        'following': FieldValue.arrayUnion([currentUserId]),
      },
    );

    // Bildirim oluştur - istek kabul edildi
    final notificationRef = _firestore.collection('notifications').doc();
    batch.set(notificationRef, {
      'type': 'follow_accepted',
      'fromUserId': currentUserId,
      'toUserId': requesterId,
      'senderName': currentUserName,
      'message': 'takip isteğini kabul etti',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  // Takip isteğini reddet
  Future<void> rejectFollowRequest(String requesterId) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('users').doc(currentUserId),
      {
        'followRequests': FieldValue.arrayRemove([requesterId]),
      },
    );

    batch.update(
      _firestore.collection('users').doc(requesterId),
      {
        'sentRequests': FieldValue.arrayRemove([currentUserId]),
      },
    );

    await batch.commit();
  }

  // Takip isteklerini getir
  Stream<List<Map<String, dynamic>>> getFollowRequests() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return [];

      final requestIds = List<String>.from(
        snapshot.data()?['followRequests'] ?? [],
      );

      if (requestIds.isEmpty) return [];

      // İstek gönderen kullanıcıların bilgilerini al
      final List<Map<String, dynamic>> requests = [];
      for (String userId in requestIds) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          requests.add({
            'id': userDoc.id,
            ...userDoc.data()!,
          });
        }
      }

      return requests;
    });
  }

  // Kullanıcının takipçilerini getir
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) return [];
    
    final followerIds = List<String>.from(userDoc.data()?['followers'] ?? []);
    
    if (followerIds.isEmpty) return [];
    
    final List<Map<String, dynamic>> followers = [];
    for (String followerId in followerIds) {
      final followerDoc = await _firestore
          .collection('users')
          .doc(followerId)
          .get();
      
      if (followerDoc.exists) {
        followers.add({
          'id': followerDoc.id,
          ...followerDoc.data()!,
        });
      }
    }
    
    return followers;
  }

  // Kullanıcının takip ettiklerini getir
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) return [];
    
    final followingIds = List<String>.from(userDoc.data()?['following'] ?? []);
    
    if (followingIds.isEmpty) return [];
    
    final List<Map<String, dynamic>> following = [];
    for (String followingId in followingIds) {
      final followingDoc = await _firestore
          .collection('users')
          .doc(followingId)
          .get();
      
      if (followingDoc.exists) {
        following.add({
          'id': followingDoc.id,
          ...followingDoc.data()!,
        });
      }
    }
    
    return following;
  }

  // Takip durumunu kontrol et
  Future<bool> isFollowing(String userId) async {
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    
    if (!currentUserDoc.exists) return false;
    
    final following = List<String>.from(currentUserDoc.data()?['following'] ?? []);
    return following.contains(userId);
  }
}