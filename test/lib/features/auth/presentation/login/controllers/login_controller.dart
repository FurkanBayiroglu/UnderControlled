import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum LoginType { email, phone }
enum LoginState { initial, codeSent, verifying, completed, error }

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State
  LoginType _loginType = LoginType.email;
  LoginState _loginState = LoginState.initial;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Phone verification için
  String? _verificationId;
  int? _resendToken;
  String? _phoneNumber;
  int _remainingTime = 0;
  
  // Getters
  LoginType get loginType => _loginType;
  LoginState get loginState => _loginState;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;
  int get remainingTime => _remainingTime;
  bool get canResend => _remainingTime == 0 && _verificationId != null;
  
  // Input türünü belirle (email mi telefon mu)
  LoginType detectInputType(String input) {
    // @ işareti varsa email
    if (input.contains('@')) {
      return LoginType.email;
    }
    
    // Sadece rakam veya telefon formatı içeriyorsa telefon
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10 || input.startsWith('5') || input.startsWith('05') || input.startsWith('+90')) {
      return LoginType.phone;
    }
    
    return LoginType.email; // Default olarak email
  }
  
  // Email ile giriş
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _loginType = LoginType.email;
      notifyListeners();
      
      print('📧 Email ile giriş: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (credential.user != null) {
        // Online durumunu güncelle
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        
        print('✅ Email girişi başarılı');
        _loginState = LoginState.completed;
      }
      
    } on FirebaseAuthException catch (e) {
      print('❌ Email giriş hatası: ${e.code}');
      _loginState = LoginState.error;
      _errorMessage = _getEmailErrorMessage(e.code);
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      _loginState = LoginState.error;
      _errorMessage = 'Giriş yapılamadı';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Telefon ile SMS gönder
  Future<void> sendPhoneVerification(String phoneNumber) async {
    try {
    _isLoading = true;
    _errorMessage = null;
    _loginType = LoginType.phone;
    notifyListeners();
    
    // Telefon numarasını formatla
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (formattedNumber.startsWith('0')) {
      formattedNumber = formattedNumber.substring(1);
    }
    
    if (!formattedNumber.startsWith('+90')) {
      if (formattedNumber.startsWith('90')) {
        formattedNumber = '+$formattedNumber';
      } else {
        formattedNumber = '+90$formattedNumber';
      }
    }
    
    _phoneNumber = formattedNumber;
    
    // Telefon numarası kayıtlı mı kontrol et
    try {
      final phoneDoc = await _firestore
          .collection('phoneNumbers')
          .doc(_phoneNumber)
          .get();
      
      if (!phoneDoc.exists) {
        _isLoading = false;
        _loginState = LoginState.error;
        _errorMessage = 'Bu telefon numarası kayıtlı değil. Lütfen önce kayıt olun.';
        notifyListeners();
        return;
      }
    } catch (e) {
      print('⚠️ Telefon kontrolü hatası: $e');
      // Firestore erişim hatası varsa devam et
    }
    
    print('📱 SMS gönderiliyor: $_phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Otomatik doğrulama');
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ SMS hatası: ${e.code} - ${e.message}');
          _isLoading = false;
          _loginState = LoginState.error;
          _errorMessage = _getPhoneErrorMessage(e.code);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ SMS gönderildi');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _loginState = LoginState.codeSent;
          _isLoading = false;
          _startTimer();
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      
    } catch (e) {
      print('❌ SMS gönderim hatası: $e');
      _isLoading = false;
      _loginState = LoginState.error;
      _errorMessage = 'SMS gönderilemedi';
      notifyListeners();
    }
  }
  
  // SMS kodunu doğrula
  Future<void> verifyPhoneCode(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = 'Doğrulama ID\'si bulunamadı';
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _loginState = LoginState.verifying;
      _errorMessage = null;
      notifyListeners();
      
      print('🔐 Kod doğrulanıyor: $smsCode');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      await _signInWithPhoneCredential(credential);
      
    } on FirebaseAuthException catch (e) {
      print('❌ Kod doğrulama hatası: ${e.code}');
      _isLoading = false;
      _loginState = LoginState.codeSent;
      _errorMessage = _getPhoneErrorMessage(e.code);
      notifyListeners();
    }
  }
  
  // Telefon credential ile giriş
  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
  try {
    // Telefon ile giriş yap
    final userCredential = await _auth.signInWithCredential(credential);
    
    if (userCredential.user != null) {
      final currentUser = userCredential.user!;
      
      // Telefon numarasından userId'yi al
      final phoneDoc = await _firestore
          .collection('phoneNumbers')
          .doc(_phoneNumber)
          .get();
      
      if (phoneDoc.exists) {
        final userId = phoneDoc.data()?['userId'];
        
        // userId ile currentUser.uid aynı olmalı veya update yerine set kullanın
        await _firestore.collection('users').doc(currentUser.uid).set({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));  // merge: true ile sadece bu alanları güncelle
        
        print('✅ Telefon girişi başarılı');
        _loginState = LoginState.completed;
      }
    }
    
    _isLoading = false;
    notifyListeners();
    
  } catch (e) {
    print('❌ Telefon giriş hatası: $e');
    _isLoading = false;
    _loginState = LoginState.error;
    _errorMessage = 'Giriş yapılamadı';
    notifyListeners();
  }
}
  
  // Timer başlat
  void _startTimer() {
    _remainingTime = 60;
    notifyListeners();
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
        return true;
      }
      return false;
    });
  }
  
  // SMS tekrar gönder
  Future<void> resendCode() async {
    if (_phoneNumber != null && canResend) {
      _startTimer();
      await sendPhoneVerification(_phoneNumber!);
    }
  }
  
  // Hata mesajları - Email
  String _getEmailErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresi kayıtlı değil';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      default:
        return 'Giriş yapılamadı';
    }
  }
  
  // Hata mesajları - Phone
  String _getPhoneErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası';
      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin';
      case 'session-expired':
        return 'Oturum süresi doldu. Tekrar deneyin';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      default:
        return 'Bir hata oluştu';
    }
  }
  
  // State'i sıfırla
  void reset() {
    _loginType = LoginType.email;
    _loginState = LoginState.initial;
    _isLoading = false;
    _errorMessage = null;
    _verificationId = null;
    _resendToken = null;
    _phoneNumber = null;
    _remainingTime = 0;
    notifyListeners();
  }
  
  // Telefon login sayfasına geç
  void switchToPhoneLogin() {
    _loginType = LoginType.phone;
    _loginState = LoginState.initial;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Email login sayfasına geç
  void switchToEmailLogin() {
    _loginType = LoginType.email;
    _loginState = LoginState.initial;
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    reset();
    super.dispose();
  }
}