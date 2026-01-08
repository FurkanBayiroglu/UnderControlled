import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  User? get currentUser => _auth.currentUser;

  // Kullanıcı verilerini getir
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Kullanıcı verilerini tek seferlik getir
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  // Profil güncelle
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore.collection('users').doc(currentUserId).update(updates);

    // Firebase Auth display name'i de güncelle
    if (name != null) {
      await _auth.currentUser?.updateDisplayName(name);
    }
  }

  // Gizlilik ayarını değiştir
  Future<void> setPrivateAccount(bool isPrivate) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'isPrivate': isPrivate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Gizlilik durumunu getir
  Future<bool> isPrivateAccount() async {
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    return doc.data()?['isPrivate'] ?? false;
  }

  // Takipçi sayısı
  Future<int> getFollowersCount(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final followers = doc.data()?['followers'] as List? ?? [];
    return followers.length;
  }

  // Takip edilen sayısı
  Future<int> getFollowingCount(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final following = doc.data()?['following'] as List? ?? [];
    return following.length;
  }

  // Bekleyen takip istekleri sayısı
  Future<int> getPendingRequestsCount() async {
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    final requests = doc.data()?['followRequests'] as List? ?? [];
    return requests.length;
  }

  // Online durumunu güncelle
  Future<void> setOnlineStatus(bool isOnline) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Çıkış yap
  Future<void> signOut() async {
    // Önce offline yap
    await setOnlineStatus(false);
    // Sonra çıkış
    await _auth.signOut();
  }

  // Hesabı sil
  Future<void> deleteAccount() async {
    final userId = currentUserId;
    final userData = await getUserData(userId);
    final username = userData?['username'];

    // Batch işlemi
    final batch = _firestore.batch();

    // Username'i sil
    if (username != null) {
      batch.delete(_firestore.collection('usernames').doc(username));
    }

    // Kullanıcı dokümanını sil
    batch.delete(_firestore.collection('users').doc(userId));

    // Batch'i uygula
    await batch.commit();

    // Firebase Auth hesabını sil
    await _auth.currentUser?.delete();
  }

  // Kullanıcı adı değiştir
  Future<bool> changeUsername(String newUsername) async {
    final lowercaseUsername = newUsername.toLowerCase();
    
    // Yeni username müsait mi kontrol et
    final existingDoc = await _firestore
        .collection('usernames')
        .doc(lowercaseUsername)
        .get();

    if (existingDoc.exists) {
      return false; // Username zaten alınmış
    }

    // Eski username'i al
    final userData = await getUserData(currentUserId);
    final oldUsername = userData?['username'];

    // Batch işlemi
    final batch = _firestore.batch();

    // Eski username'i sil
    if (oldUsername != null) {
      batch.delete(_firestore.collection('usernames').doc(oldUsername));
    }

    // Yeni username'i ekle
    batch.set(_firestore.collection('usernames').doc(lowercaseUsername), {
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // User dokümanını güncelle
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'username': lowercaseUsername,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return true;
  }
}
