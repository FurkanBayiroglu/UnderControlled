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
  Future<void> signInWithEmail(String email, String password, {bool isTurkish = true}) async {
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
      _errorMessage = _getEmailErrorMessage(e.code, isTurkish: isTurkish);
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
      _loginState = LoginState.error;
      _errorMessage = isTurkish ? 'Giriş yapılamadı. Bilgilerinizi kontrol edin' : 'Login failed. Check your credentials';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Telefon ile SMS gönder
  Future<void> sendPhoneVerification(String phoneNumber, {bool isTurkish = true}) async {
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
    
    // Telefon numarası kayıtlı mı kontrol et (phoneNumbers VEYA users'dan)
    try {
      bool isRegistered = false;
      
      // 1. phoneNumbers'dan kontrol
      final phoneDoc = await _firestore
          .collection('phoneNumbers')
          .doc(_phoneNumber)
          .get();
      
      if (phoneDoc.exists) {
        isRegistered = true;
        print('✅ phoneNumbers\'da bulundu');
      } else {
        // 2. users collection'dan telefon ile ara
        final usersQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: _phoneNumber)
            .limit(1)
            .get();
        
        if (usersQuery.docs.isNotEmpty) {
          isRegistered = true;
          print('✅ users\'da bulundu');
        }
      }
      
      if (!isRegistered) {
        _isLoading = false;
        _loginState = LoginState.error;
        _errorMessage = isTurkish 
            ? 'Bu telefon numarası kayıtlı değil. Lütfen önce kayıt olun.' 
            : 'This phone number is not registered. Please sign up first.';
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
          await _signInWithPhoneCredential(credential, isTurkish: isTurkish);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ SMS hatası: ${e.code} - ${e.message}');
          _isLoading = false;
          _loginState = LoginState.error;
          _errorMessage = _getPhoneErrorMessage(e.code, isTurkish: isTurkish);
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
      _errorMessage = isTurkish ? 'SMS gönderilemedi' : 'Failed to send SMS';
      notifyListeners();
    }
  }
  
  // SMS kodunu doğrula
  Future<void> verifyPhoneCode(String smsCode, {bool isTurkish = true}) async {
    if (_verificationId == null) {
      _errorMessage = isTurkish ? 'Doğrulama ID\'si bulunamadı' : 'Verification ID not found';
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
      
      await _signInWithPhoneCredential(credential, isTurkish: isTurkish);
      
    } on FirebaseAuthException catch (e) {
      print('❌ Kod doğrulama hatası: ${e.code}');
      _isLoading = false;
      _loginState = LoginState.codeSent;
      _errorMessage = _getPhoneErrorMessage(e.code, isTurkish: isTurkish);
      notifyListeners();
    }
  }
  
  // Telefon credential ile giriş
  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential, {bool isTurkish = true}) async {
    try {
      // Telefon ile giriş yap
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final currentUser = userCredential.user!;
        print('🔐 Firebase Auth UID: ${currentUser.uid}');
        print('📱 Telefon numarası: $_phoneNumber');
        
        String? originalUserId;
        Map<String, dynamic>? originalData;
        
        // 1. Önce phoneNumbers collection'dan dene
        final phoneDoc = await _firestore
            .collection('phoneNumbers')
            .doc(_phoneNumber)
            .get();
        
        print('📄 phoneNumbers.exists: ${phoneDoc.exists}');
        
        if (phoneDoc.exists) {
          originalUserId = phoneDoc.data()?['userId'] as String?;
          print('👤 phoneNumbers\'dan userId: $originalUserId');
        }
        
        // 2. phoneNumbers'da yoksa, users collection'dan telefon ile ara
        if (originalUserId == null) {
          print('🔍 users collection\'dan telefon ile aranıyor...');
          final usersQuery = await _firestore
              .collection('users')
              .where('phone', isEqualTo: _phoneNumber)
              .limit(1)
              .get();
          
          if (usersQuery.docs.isNotEmpty) {
            originalUserId = usersQuery.docs.first.id;
            originalData = usersQuery.docs.first.data();
            print('✅ users\'dan bulundu: $originalUserId');
            
            // phoneNumbers'a da ekle (eksikse)
            await _firestore.collection('phoneNumbers').doc(_phoneNumber).set({
              'userId': originalUserId,
              'createdAt': FieldValue.serverTimestamp(),
            });
            print('✅ phoneNumbers\'a eklendi');
          }
        }
        
        // 3. Hala bulunamadıysa, mevcut kullanıcıyı kontrol et
        if (originalUserId == null) {
          final currentUserDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          if (currentUserDoc.exists) {
            print('✅ Mevcut kullanıcı zaten var');
            await _firestore.collection('users').doc(currentUser.uid).update({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
              'phone': _phoneNumber, // Telefonu güncelle
            });
            _loginState = LoginState.completed;
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
        
        print('👤 Original userId: $originalUserId');
        print('👤 Current userId: ${currentUser.uid}');
        
        // Migration gerekli mi?
        if (originalUserId != null && originalUserId != currentUser.uid) {
          print('🔄 Migration başlıyor: $originalUserId -> ${currentUser.uid}');
          
          // Orijinal veriyi al (eğer henüz alınmadıysa)
          if (originalData == null) {
            final originalUserDoc = await _firestore
                .collection('users')
                .doc(originalUserId)
                .get();
            
            if (originalUserDoc.exists) {
              originalData = originalUserDoc.data();
            }
          }
          
          if (originalData != null) {
            print('📋 Orijinal veri anahtarları: ${originalData.keys.toList()}');
            
            // Yeni uid ile kullanıcı dokümanı oluştur
            await _firestore.collection('users').doc(currentUser.uid).set({
              ...originalData,
              'uid': currentUser.uid,
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
              'migratedFrom': originalUserId,
              'migratedAt': FieldValue.serverTimestamp(),
            });
            print('✅ users güncellendi');
            
            // phoneNumbers güncelle
            await _firestore.collection('phoneNumbers').doc(_phoneNumber).set({
              'userId': currentUser.uid,
              'previousUserId': originalUserId,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            print('✅ phoneNumbers güncellendi');
            
            // usernames güncelle
            final username = originalData['username'] as String?;
            if (username != null) {
              await _firestore.collection('usernames').doc(username).set({
                'userId': currentUser.uid,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              print('✅ usernames güncellendi');
            }
            
            print('✅ Migration tamamlandı!');
            _loginState = LoginState.completed;
          } else {
            print('❌ Orijinal kullanıcı verisi bulunamadı - sign out yapılıyor');
            await _auth.signOut();
            _loginState = LoginState.error;
            _errorMessage = isTurkish ? 'Kullanıcı verisi bulunamadı' : 'User data not found';
          }
        } else if (originalUserId == currentUser.uid) {
          print('✅ Aynı kullanıcı, migration gerekmez');
          
          // Users'da kayıt var mı kontrol et
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          
          if (userDoc.exists) {
            print('✅ users\'da kayıt var, online güncelleniyor');
            await _firestore.collection('users').doc(currentUser.uid).update({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            });
          } else {
            print('⚠️ users\'da kayıt YOK! Temel veri oluşturuluyor...');
            // Temel kullanıcı verisi oluştur
            await _firestore.collection('users').doc(currentUser.uid).set({
              'uid': currentUser.uid,
              'phone': _phoneNumber,
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'name': 'Kullanıcı',
              'username': 'user_${currentUser.uid.substring(0, 8)}',
              'bio': '',
              'photoUrl': '',
              'isPremium': false,
            });
            print('✅ Temel kullanıcı verisi oluşturuldu');
          }
          
          _loginState = LoginState.completed;
        } else {
          print('❌ Kullanıcı bulunamadı - sign out yapılıyor');
          // ÖNEMLİ: Firebase Auth'dan çıkış yap, yoksa ana sayfaya yönlendirir
          await _auth.signOut();
          _loginState = LoginState.error;
          _errorMessage = isTurkish ? 'Bu telefon numarası kayıtlı değil' : 'This phone number is not registered';
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      print('❌ Telefon giriş hatası: $e');
      // Hata durumunda da sign out yap
      await _auth.signOut();
      _isLoading = false;
      _loginState = LoginState.error;
      _errorMessage = isTurkish ? 'Giriş yapılamadı' : 'Login failed';
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
  String _getEmailErrorMessage(String code, {bool isTurkish = true}) {
    switch (code) {
      case 'user-not-found':
        return isTurkish ? 'Bu e-posta adresi kayıtlı değil' : 'Email not registered';
      case 'wrong-password':
        return isTurkish ? 'Şifre hatalı' : 'Wrong password';
      case 'invalid-credential':
        return isTurkish ? 'E-posta veya şifre hatalı' : 'Invalid email or password';
      case 'invalid-email':
        return isTurkish ? 'Geçersiz e-posta adresi' : 'Invalid email address';
      case 'user-disabled':
        return isTurkish ? 'Bu hesap devre dışı bırakılmış' : 'This account has been disabled';
      case 'too-many-requests':
        return isTurkish ? 'Çok fazla deneme. Lütfen biraz bekleyin' : 'Too many attempts. Please wait';
      case 'network-request-failed':
        return isTurkish ? 'İnternet bağlantınızı kontrol edin' : 'Check your internet connection';
      case 'operation-not-allowed':
        return isTurkish ? 'Bu giriş yöntemi devre dışı' : 'This sign-in method is disabled';
      case 'email-already-in-use':
        return isTurkish ? 'Bu e-posta zaten kullanımda' : 'Email already in use';
      default:
        return isTurkish ? 'Giriş yapılamadı. Bilgilerinizi kontrol edin' : 'Login failed. Check your credentials';
    }
  }
  
  // Hata mesajları - Phone
  String _getPhoneErrorMessage(String code, {bool isTurkish = true}) {
    switch (code) {
      case 'invalid-phone-number':
        return isTurkish ? 'Geçersiz telefon numarası' : 'Invalid phone number';
      case 'invalid-verification-code':
        return isTurkish ? 'Doğrulama kodu hatalı' : 'Invalid verification code';
      case 'too-many-requests':
        return isTurkish ? 'Çok fazla deneme. Lütfen bekleyin' : 'Too many attempts. Please wait';
      case 'session-expired':
        return isTurkish ? 'Süre doldu. Tekrar kod gönderin' : 'Session expired. Resend code';
      case 'network-request-failed':
        return isTurkish ? 'İnternet bağlantınızı kontrol edin' : 'Check your internet connection';
      case 'quota-exceeded':
        return isTurkish ? 'SMS limiti aşıldı. Daha sonra deneyin' : 'SMS quota exceeded. Try later';
      default:
        return isTurkish ? 'Bir hata oluştu. Tekrar deneyin' : 'An error occurred. Try again';
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