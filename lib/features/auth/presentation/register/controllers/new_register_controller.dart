import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/auth_service.dart';

enum RegisterState {
  initial,
  dataEntered,
  sendingCode,
  codeSent,
  verifying,
  completed,
  error
}

class NewRegisterController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  // State
  RegisterState _state = RegisterState.initial;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Phone verification
  String? _verificationId;
  int? _resendToken;
  int _remainingTime = 0;
  Timer? _timer;
  
  // User data
  String? _name;
  String? _username;
  String? _email;
  String? _password;
  String? _phoneNumber;
  
  // Username checking
  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  String? _usernameError;
  
  // Getters
  RegisterState get state => _state;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get remainingTime => _remainingTime;
  bool get canResend => _remainingTime == 0 && _verificationId != null;
  bool get isCheckingUsername => _isCheckingUsername;
  bool get isUsernameAvailable => _isUsernameAvailable;
  String? get usernameError => _usernameError;
  String? get phoneNumber => _phoneNumber;
  
  // Username kontrolü (debounce ile)
  void checkUsername(String username) {
    _debounceTimer?.cancel();
    
    if (username.isEmpty) {
      _usernameError = null;
      _isUsernameAvailable = false;
      _isCheckingUsername = false;
      notifyListeners();
      return;
    }
    
    // Format kontrolü
    final formatError = _validateUsernameFormat(username);
    if (formatError != null) {
      _usernameError = formatError;
      _isUsernameAvailable = false;
      _isCheckingUsername = false;
      notifyListeners();
      return;
    }
    
    _isCheckingUsername = true;
    _usernameError = null;
    notifyListeners();
    
    // Debounce: 800ms bekle
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final isAvailable = await _authService.checkUsernameAvailability(username);
        
        _isCheckingUsername = false;
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Bu kullanıcı adı alınmış';
        notifyListeners();
      } catch (e) {
        print('! Telefon kontrolü hatası: $e');
        _isCheckingUsername = false;
        // Permission hatası durumunda devam etmesine izin ver
        _isUsernameAvailable = true;
        _usernameError = null;
        notifyListeners();
      }
    });
  }
  
  // Format kontrolü
  String? _validateUsernameFormat(String username) {
    username = username.toLowerCase();
    
    if (username.length < 3) return 'En az 3 karakter';
    if (username.length > 20) return 'En fazla 20 karakter';
    if (!RegExp(r'^[a-z][a-z0-9._]*$').hasMatch(username)) {
      return 'Harf ile başlamalı, özel karakter kullanılamaz';
    }
    if (username.endsWith('.')) return 'Nokta ile bitemez';
    if (username.contains('..') || username.contains('__')) {
      return 'Ardışık nokta veya alt çizgi kullanılamaz';
    }
    
    const reserved = ['admin', 'root', 'system', 'moderator'];
    if (reserved.contains(username)) {
      return 'Bu kullanıcı adı rezerve edilmiş';
    }
    
    return null;
  }
  
  // Telefon numarası doğrulama
  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }
    
    // Sadece rakamları al
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Türkiye telefon numarası kontrolü (10 haneli, 5 ile başlamalı)
    if (!digitsOnly.startsWith('5') || digitsOnly.length != 10) {
      return 'Geçerli bir telefon numarası girin (5XX XXX XX XX)';
    }
    
    return null;
  }
  
  // Timer başlat
  void _startTimer() {
    _remainingTime = 60;
    notifyListeners();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }
  
  // Formu kaydet ve SMS gönder
  Future<void> submitFormAndSendCode({
    required String name,
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Verileri kaydet
      _name = name;
      _username = username.toLowerCase();
      _email = email;
      _password = password;
      
      // Telefon numarasını formatla
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (!formattedNumber.startsWith('+90')) {
        if (formattedNumber.startsWith('90')) {
          formattedNumber = '+$formattedNumber';
        } else if (formattedNumber.startsWith('0')) {
          formattedNumber = '+9$formattedNumber';
        } else {
          formattedNumber = '+90$formattedNumber';
        }
      }
      _phoneNumber = formattedNumber;
      
      print('📱 Kayıt bilgileri alındı, SMS gönderiliyor: $_phoneNumber');
      
      // SMS gönder
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Otomatik doğrulama başarılı');
          await _completeRegistration(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ SMS gönderim hatası: ${e.code} - ${e.message}');
          _isLoading = false;
          _state = RegisterState.error;
          _errorMessage = _getErrorMessage(e.code);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ SMS gönderildi. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _state = RegisterState.codeSent;
          _isLoading = false;
          _startTimer();
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Otomatik kod alma zaman aşımı');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      
    } catch (e) {
      print('❌ Form gönderim hatası: $e');
      _isLoading = false;
      _state = RegisterState.error;
      _errorMessage = 'Bir hata oluştu: $e';
      notifyListeners();
    }
  }
  
  // SMS kodunu doğrula
  Future<void> verifyCode(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = 'Doğrulama ID\'si bulunamadı';
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _state = RegisterState.verifying;
      _errorMessage = null;
      notifyListeners();
      
      print('🔐 Kod doğrulanıyor: $smsCode');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      await _completeRegistration(credential);
      
    } on FirebaseAuthException catch (e) {
      print('❌ Kod doğrulama hatası: ${e.code}');
      _isLoading = false;
      _state = RegisterState.codeSent;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      _isLoading = false;
      _state = RegisterState.error;
      _errorMessage = 'Kod doğrulanamadı: $e';
      notifyListeners();
    }
  }
  
  // Kayıt işlemini tamamla
  Future<void> _completeRegistration(PhoneAuthCredential phoneCredential) async {
    try {
      print('📝 Kayıt işlemi başlıyor...');
      
      // Önce telefon numarası ile giriş yap (doğrula)
      final phoneUserCredential = await _auth.signInWithCredential(phoneCredential);
      final phoneUserId = phoneUserCredential.user?.uid;
      
      if (phoneUserId == null) {
        throw Exception('Telefon doğrulaması başarısız');
      }
      
      print('✅ Telefon doğrulandı: $phoneUserId');
      
      // Şimdi email ve şifre ile yeni kullanıcı oluştur
      await _auth.signOut(); // Önce çıkış yap
      
      final emailUserCredential = await _auth.createUserWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );
      
      final user = emailUserCredential.user;
      if (user == null) {
        throw Exception('Kullanıcı oluşturulamadı');
      }
      
      print('✅ Email kullanıcısı oluşturuldu: ${user.uid}');
      
      // Display name güncelle
      await user.updateDisplayName(_name);
      
      // Firestore'a kullanıcı bilgilerini kaydet
      final batch = _firestore.batch();
      
      // Users koleksiyonu
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, {
        'uid': user.uid,
        'name': _name,
        'username': _username,
        'email': _email,
        'phoneNumber': _phoneNumber,
        'photoUrl': null,
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'followers': [],
        'following': [],
        'isVerified': false,
        'isPhoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      });
      
      // Usernames koleksiyonu
      final usernameRef = _firestore.collection('usernames').doc(_username);
      batch.set(usernameRef, {
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Phone numbers koleksiyonu (telefon numarası ile kullanıcı eşleştirme için)
      final phoneRef = _firestore.collection('phoneNumbers').doc(_phoneNumber);
      batch.set(phoneRef, {
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      print('✅ Firestore kayıtları tamamlandı');
      
      _state = RegisterState.completed;
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      print('❌ Kayıt tamamlama hatası: $e');
      _isLoading = false;
      _state = RegisterState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // Tekrar SMS gönder
  Future<void> resendCode() async {
    if (_phoneNumber != null && canResend) {
      _startTimer();
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _completeRegistration(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = _getErrorMessage(e.code);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );
    }
  }
  
  // Hata mesajlarını düzenle
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu';
      case 'session-expired':
        return 'Oturum süresi doldu. Tekrar deneyin';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
  
  // State'i sıfırla
  void reset() {
    _state = RegisterState.initial;
    _isLoading = false;
    _errorMessage = null;
    _verificationId = null;
    _resendToken = null;
    _remainingTime = 0;
    _timer?.cancel();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}