import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı kaydı
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      print('📝 RegisterUser başladı: $email');
      
      // Firebase Auth ile kullanıcı oluştur
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Auth kullanıcısı oluşturuldu: ${credential.user?.uid}');

      if (credential.user != null) {
        // Display name'i güncelle
        await credential.user!.updateDisplayName(name);
        print('✅ Display name güncellendi: $name');

        print('🔄 Firestore\'a yazılıyor...');
        // Firestore'a kullanıcı bilgilerini kaydet
        await _saveUserToFirestore(
          userId: credential.user!.uid,
          email: email,
          name: name,
          username: username,
        );
        print('✅ Firestore\'a yazıldı!');

        return credential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ Auth hatası: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Genel hata: $e');
      print('❌ Hata tipi: ${e.runtimeType}');
      rethrow;
    }
  }

  // Kullanıcı girişi
  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Giriş yapılıyor: $email');
      
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Giriş başarılı: ${credential.user?.uid}');
      
      // Online durumunu güncelle
      if (credential.user != null) {
        await _updateUserOnlineStatus(credential.user!.uid, true);
      }
      
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Giriş hatası: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Genel giriş hatası: $e');
      rethrow;
    }
  }

  // Firestore'a kullanıcı bilgilerini kaydet
  Future<void> _saveUserToFirestore({
    required String userId,
    required String email,
    required String name,
    required String username,
  }) async {
    try {
      print('📝 Firestore batch başlıyor...');
      
      // WriteBatch kullan
      final WriteBatch batch = _firestore.batch();

      // Users koleksiyonuna kullanıcı ekle
      final DocumentReference userRef = _firestore.collection('users').doc(userId);
      // _saveUserToFirestore metodunda bu satırı değiştir:
batch.set(userRef, {
  'uid': userId,
  'name': name,
  'username': username.toLowerCase(),
  'email': email,
  'photoUrl': null,
  'bio': '',
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'isOnline': true,
  'lastSeen': FieldValue.serverTimestamp(),
  'followers': [],
  'following': [],
  'followRequests': [],    // EKLENDİ
  'sentRequests': [],      // EKLENDİ
  'isPrivate': true,       // DEĞİŞTİRİLDİ - Artık varsayılan olarak private
  'isVerified': false,
});
      print('✅ User document hazırlandı');

      // Usernames koleksiyonuna username ekle (benzersizlik için)
      final DocumentReference usernameRef = _firestore.collection('usernames').doc(username.toLowerCase());
      batch.set(usernameRef, {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Username document hazırlandı');

      // Batch'i commit et
      await batch.commit();
      print('✅ Batch commit başarılı!');
      
    } catch (e) {
      print('❌ Firestore hatası: $e');
      print('❌ Hata detayı: ${e.toString()}');
      
      // Eğer Firestore'a yazamazsa, oluşturulan Auth kullanıcısını sil
      try {
        await _auth.currentUser?.delete();
        print('⚠️ Firestore hatası nedeniyle Auth kullanıcısı silindi');
      } catch (deleteError) {
        print('❌ Auth kullanıcısı silinemedi: $deleteError');
      }
      
      rethrow;
    }
  }

  // Kullanıcı verilerini Firestore'dan getir
  Future<UserModel?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Kullanıcı verisi getirilemedi: $e');
      return null;
    }
  }

  // Kullanıcı online durumunu güncelle
  Future<void> _updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Online durum güncellenemedi: $e');
    }
  }

  // Username kontrolü
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      
      return !doc.exists;
    } catch (e) {
      print('❌ Username kontrol hatası: $e');
      // Hata durumunda güvenli tarafta kal
      return false;
    }
  }

  // Kullanıcı verilerini sil (hesap silme için)
  Future<void> deleteUserData(String userId) async {
    try {
      // Batch ile tüm ilgili verileri sil
      final WriteBatch batch = _firestore.batch();
      
      // Kullanıcı dokümantını al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        // Username dokümantını sil
        final username = userDoc.data()?['username'];
        if (username != null) {
          batch.delete(_firestore.collection('usernames').doc(username));
        }
        
        // Kullanıcı dokümantını sil
        batch.delete(_firestore.collection('users').doc(userId));
        
        await batch.commit();
      }
    } catch (e) {
      print('❌ Kullanıcı verileri silinemedi: $e');
      rethrow;
    }
  }

  // Hata mesajlarını düzenle
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter)';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanılıyor';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen biraz bekleyin';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farklı bir yöntemle kayıtlı';
      default:
        return 'Bir hata oluştu: ${e.message ?? e.code}';
    }
  }
}