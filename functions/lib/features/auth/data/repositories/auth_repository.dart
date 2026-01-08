  import 'dart:async';
  import 'package:firebase_auth/firebase_auth.dart';
  import '../services/auth_service.dart';
  import '../../domain/models/user_model.dart';

  // Repository interface
  abstract class AuthRepository {
    Stream<User?> get authStateChanges;
    Future<UserModel?> getCurrentUser();
    Future<UserModel?> signIn(String email, String password);
    Future<UserModel?> signUp({
      required String email,
      required String password,
      required String name,
      required String username,
    });
    Future<void> signOut();
    Future<void> sendPasswordResetEmail(String email);
    Future<bool> checkUsernameAvailability(String username);
  }

  // Repository implementation
  class AuthRepositoryImpl implements AuthRepository {
    final AuthService _authService;
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    AuthRepositoryImpl({AuthService? authService})
        : _authService = authService ?? AuthService();

    @override
    Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

    @override
    Future<UserModel?> getCurrentUser() async {
      try {
        final user = _firebaseAuth.currentUser;
        if (user == null) return null;

        // Firestore'dan kullanıcı bilgilerini getir
        final userData = await _authService.getUserData(user.uid);
        return userData;
      } catch (e) {
        print('Get current user error: $e');
        return null;
      }
    }

    @override
    Future<UserModel?> signIn(String email, String password) async {
      try {
        final user = await _authService.signInUser(
          email: email,
          password: password,
        );
        
        if (user != null) {
          // Firestore'dan kullanıcı bilgilerini getir
          return await _authService.getUserData(user.uid);
        }
        return null;
      } catch (e) {
        rethrow;
      }
    }

    @override
    Future<UserModel?> signUp({
      required String email,
      required String password,
      required String name,
      required String username,
    }) async {
      try {
        final user = await _authService.registerUser(
          email: email,
          password: password,
          name: name,
          username: username,
        );
        
        if (user != null) {
          // Yeni oluşturulan kullanıcı modelini döndür
          return UserModel(
            uid: user.uid,
            email: email,
            name: name,
            username: username,
            createdAt: DateTime.now(),
          );
        }
        return null;
      } catch (e) {
        rethrow;
      }
    }

    @override
    Future<void> signOut() async {
      try {
        await _firebaseAuth.signOut();
      } catch (e) {
        throw Exception('Çıkış yapılamadı: $e');
      }
    }

    @override
    Future<void> sendPasswordResetEmail(String email) async {
      try {
        await _firebaseAuth.sendPasswordResetEmail(email: email);
      } on FirebaseAuthException catch (e) {
        String message = 'Bir hata oluştu';
        
        switch (e.code) {
          case 'user-not-found':
            message = 'Bu e-posta adresi kayıtlı değil';
            break;
          case 'invalid-email':
            message = 'Geçersiz e-posta adresi';
            break;
        }
        
        throw Exception(message);
      }
    }

    @override
    Future<bool> checkUsernameAvailability(String username) async {
      return await _authService.checkUsernameAvailability(username);
    }

    // Ek yardımcı metodlar
    User? get currentUser => _firebaseAuth.currentUser;
    
    bool get isAuthenticated => currentUser != null;
    
    String? get currentUserId => currentUser?.uid;
    
    String? get currentUserEmail => currentUser?.email;
    
    // Email doğrulama
    Future<void> sendEmailVerification() async {
      try {
        await currentUser?.sendEmailVerification();
      } catch (e) {
        throw Exception('Doğrulama e-postası gönderilemedi: $e');
      }
    }
    
    // Şifre güncelleme
    Future<void> updatePassword(String newPassword) async {
      try {
        await currentUser?.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        String message = 'Şifre güncellenemedi';
        
        if (e.code == 'requires-recent-login') {
          message = 'Bu işlem için yeniden giriş yapmanız gerekiyor';
        } else if (e.code == 'weak-password') {
          message = 'Şifre çok zayıf';
        }
        
        throw Exception(message);
      }
    }
    
    // Hesap silme
    Future<void> deleteAccount() async {
      try {
        final userId = currentUser?.uid;
        if (userId != null) {
          // Önce Firestore'dan kullanıcı verilerini sil
          await _authService.deleteUserData(userId);
          // Sonra Auth'tan kullanıcıyı sil
          await currentUser?.delete();
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Hesap silinemedi';
        
        if (e.code == 'requires-recent-login') {
          message = 'Bu işlem için yeniden giriş yapmanız gerekiyor';
        }
        
        throw Exception(message);
      }
    }
  }