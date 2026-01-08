import 'package:cloud_firestore/cloud_firestore.dart';

/// Premium paket tipleri
enum PremiumPlan {
  monthly,
  quarterly,
  yearly,
}

/// Premium paket bilgileri
class PremiumPackage {
  final PremiumPlan plan;
  final String id;
  final String name;
  final String nameEn;
  final double price;
  final int durationDays;
  final double? discountPercent;
  final bool isPopular;

  const PremiumPackage({
    required this.plan,
    required this.id,
    required this.name,
    required this.nameEn,
    required this.price,
    required this.durationDays,
    this.discountPercent,
    this.isPopular = false,
  });

  double get monthlyPrice => price / (durationDays / 30);

  static const List<PremiumPackage> packages = [
    PremiumPackage(
      plan: PremiumPlan.monthly,
      id: 'premium_monthly',
      name: 'Aylık',
      nameEn: 'Monthly',
      price: 49.99,
      durationDays: 30,
    ),
    PremiumPackage(
      plan: PremiumPlan.quarterly,
      id: 'premium_quarterly',
      name: '3 Aylık',
      nameEn: '3 Months',
      price: 119.99,
      durationDays: 90,
      discountPercent: 20,
    ),
    PremiumPackage(
      plan: PremiumPlan.yearly,
      id: 'premium_yearly',
      name: 'Yıllık',
      nameEn: 'Yearly',
      price: 359.99,
      durationDays: 365,
      discountPercent: 40,
      isPopular: true,
    ),
  ];
}

/// Kullanıcının premium durumu
class PremiumStatus {
  final bool isPremium;
  final DateTime? expiryDate;
  final PremiumPlan? currentPlan;
  final DateTime? purchaseDate;

  const PremiumStatus({
    this.isPremium = false,
    this.expiryDate,
    this.currentPlan,
    this.purchaseDate,
  });

  /// Kalan gün sayısı
  int get daysRemaining {
    if (!isPremium || expiryDate == null) return 0;
    final remaining = expiryDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Premium hala geçerli mi
  bool get isActive {
    if (!isPremium || expiryDate == null) return false;
    return expiryDate!.isAfter(DateTime.now());
  }

  factory PremiumStatus.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PremiumStatus();
    
    // premiumExpiryDate veya premiumExpiry olabilir (geriye uyumluluk)
    final expiryData = data['premiumExpiryDate'] ?? data['premiumExpiry'];
    
    return PremiumStatus(
      isPremium: data['isPremium'] ?? false,
      expiryDate: expiryData != null 
          ? (expiryData as Timestamp).toDate() 
          : null,
      currentPlan: data['premiumPlan'] != null 
          ? PremiumPlan.values.firstWhere(
              (e) => e.name == data['premiumPlan'],
              orElse: () => PremiumPlan.monthly,
            )
          : null,
      purchaseDate: data['premiumPurchaseDate'] != null 
          ? (data['premiumPurchaseDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'isPremium': isPremium,
    'premiumExpiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    'premiumPlan': currentPlan?.name,
    'premiumPurchaseDate': purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
  };
}

/// Premium özelliklerin limitleri
class PremiumLimits {
  // Oda limitleri
  static const int freeMaxRooms = 3;
  static const int premiumMaxRooms = 999; // Sınırsız
  
  static const int freeMaxParticipants = 20;
  static const int premiumMaxParticipants = 100;
  
  // Mesaj limitleri
  static const int freeMessageDeleteMinutes = 5;
  static const int premiumMessageDeleteHours = 24;
  
  // Takip limitleri
  static const int freeMaxFollowing = 500;
  static const int premiumMaxFollowing = 5000;
}
