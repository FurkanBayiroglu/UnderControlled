import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _successEmail;
  
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
  String? get successEmail => _successEmail;
  
  // Email gönder
  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    _successEmail = null;
    notifyListeners();
    
    try {
      print('🔐 Şifre sıfırlama başlatılıyor: $email');
      
      // Email'i temizle ve küçük harfe çevir
      final cleanEmail = email.trim().toLowerCase();
      print('🔐 Temizlenmiş email: $cleanEmail');
      
      // Firebase'e gönder
      await _auth.sendPasswordResetEmail(email: cleanEmail);
      
      print('✅ Şifre sıfırlama emaili başarıyla gönderildi!');
      
      _isSuccess = true;
      _successEmail = cleanEmail;
      _errorMessage = null;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Hatası: ${e.code}');
      print('❌ Hata Mesajı: ${e.message}');
      
      _isSuccess = false;
      _errorMessage = _handleAuthException(e);
      
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      _isSuccess = false;
      _errorMessage = 'Beklenmedik bir hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Email formatı kontrolü
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gerekli';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }
    
    return null;
  }
  
  // Hata mesajlarını düzenle
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      case 'missing-email':
        return 'E-posta adresi girilmedi';
      case 'unauthorized-continue-uri':
        return 'Domain yetkilendirilmemiş';
      case 'invalid-continue-uri':
        return 'Geçersiz devam URL\'i';
      default:
        return 'Şifre sıfırlama e-postası gönderilemedi: ${e.message ?? e.code}';
    }
  }
  
  // Formu sıfırla
  void reset() {
    _isSuccess = false;
    _errorMessage = null;
    _successEmail = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    reset();
    super.dispose();
  }
}