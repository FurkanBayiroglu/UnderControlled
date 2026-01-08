import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'premium_model.dart';

class PremiumService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  PremiumStatus _status = const PremiumStatus();
  bool _isLoading = false;

  PremiumStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isPremium => _status.isActive;

  String? get _currentUserId => _auth.currentUser?.uid;

  PremiumService() {
    _init();
  }

  Future<void> _init() async {
    if (_currentUserId != null) {
      await loadPremiumStatus();
    }
    
    // Auth değişikliklerini dinle
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadPremiumStatus();
      } else {
        _status = const PremiumStatus();
        notifyListeners();
      }
    });
  }

  /// Premium durumunu yükle
  Future<void> loadPremiumStatus() async {
    if (_currentUserId == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        _status = PremiumStatus.fromMap(doc.data());
        
        // Süresi dolmuşsa güncelle
        if (_status.isPremium && !_status.isActive) {
          await _expirePremium();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Premium status load error: $e');
    }
  }

  /// Premium satın al
  Future<bool> purchasePremium(PremiumPackage package) async {
    if (_currentUserId == null) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime expiryDate;
      
      // Mevcut premium varsa süreyi uzat
      if (_status.isActive && _status.expiryDate != null) {
        expiryDate = _status.expiryDate!.add(Duration(days: package.durationDays));
      } else {
        expiryDate = now.add(Duration(days: package.durationDays));
      }

      // Firestore'a kaydet
      await _firestore.collection('users').doc(_currentUserId).update({
        'isPremium': true,
        'premiumExpiryDate': Timestamp.fromDate(expiryDate),
        'premiumPlan': package.plan.toString().split('.').last,
        'premiumPurchaseDate': Timestamp.fromDate(now),
      });

      _status = PremiumStatus(
        isPremium: true,
        expiryDate: expiryDate,
        currentPlan: package.plan,
        purchaseDate: now,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Premium purchase error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Premium süresini uzat
  Future<bool> extendPremium(PremiumPackage package) async {
    return await purchasePremium(package);
  }

  /// Premium süresini bitir
  Future<void> _expirePremium() async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'isPremium': false,
      });
      
      _status = PremiumStatus(
        isPremium: false,
        expiryDate: _status.expiryDate,
        currentPlan: _status.currentPlan,
        purchaseDate: _status.purchaseDate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Premium expire error: $e');
    }
  }

  /// Kullanıcının oda oluşturma limitini kontrol et
  Future<bool> canCreateRoom() async {
    if (isPremium) return true;
    if (_currentUserId == null) return false;

    try {
      final rooms = await _firestore
          .collection('rooms')
          .where('createdBy', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return rooms.docs.length < PremiumLimits.freeMaxRooms;
    } catch (e) {
      return false;
    }
  }

  /// Kullanıcının kaç oda oluşturabileceğini getir
  Future<int> getRemainingRoomSlots() async {
    if (isPremium) return PremiumLimits.premiumMaxRooms;
    if (_currentUserId == null) return 0;

    try {
      final rooms = await _firestore
          .collection('rooms')
          .where('createdBy', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .get();
      
      final remaining = PremiumLimits.freeMaxRooms - rooms.docs.length;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Maksimum katılımcı sayısı
  int get maxParticipants => isPremium 
      ? PremiumLimits.premiumMaxParticipants 
      : PremiumLimits.freeMaxParticipants;

  /// Profil fotoğrafı yükleyebilir mi
  bool get canUploadProfilePhoto => isPremium;

  /// Mesaj silme süresi (dakika)
  int get messageDeleteMinutes => isPremium 
      ? PremiumLimits.premiumMessageDeleteHours * 60 
      : PremiumLimits.freeMessageDeleteMinutes;

  /// Premium durumunu stream olarak dinle
  Stream<PremiumStatus> get premiumStatusStream {
    if (_currentUserId == null) {
      return Stream.value(const PremiumStatus());
    }
    
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) => PremiumStatus.fromMap(doc.data()));
  }

  /// Belirli bir kullanıcının premium olup olmadığını kontrol et
  Future<bool> isUserPremium(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      
      final status = PremiumStatus.fromMap(doc.data());
      return status.isActive;
    } catch (e) {
      return false;
    }
  }
}
