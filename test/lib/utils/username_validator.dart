import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameValidator {
  // Yasaklı kullanıcı adları
  static const List<String> reservedUsernames = [
    'admin', 'root', 'system', 'moderator', 'mod', 'owner',
    'undercontrolled', 'official', 'support', 'help', 'info',
  ];

  // Kullanıcı adı formatını kontrol et
  static String? validateFormat(String? username) {
    if (username == null || username.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }

    username = username.toLowerCase();

    if (username.length < 3) {
      return 'En az 3 karakter olmalı';
    }
    if (username.length > 20) {
      return 'En fazla 20 karakter olabilir';
    }

    if (!RegExp(r'^[a-z][a-z0-9._]*$').hasMatch(username)) {
      return 'Harf ile başlamalı, sadece küçük harf, sayı, nokta ve alt çizgi içerebilir';
    }

    if (username.endsWith('.')) {
      return 'Nokta ile bitemez';
    }

    if (username.contains('..') || username.contains('__')) {
      return 'Ardışık nokta veya alt çizgi kullanılamaz';
    }

    if (reservedUsernames.contains(username)) {
      return 'Bu kullanıcı adı rezerve edilmiş';
    }

    return null;
  }

  // Firestore'da kullanıcı adı müsait mi kontrol et (retry logic ile)
  static Future<bool> isUsernameAvailable(String username) async {
    username = username.toLowerCase();
    
    // 3 deneme yap
    for (int i = 0; i < 3; i++) {
      try {
        print('Username kontrol deneme ${i + 1}: $username');
        
        final docSnapshot = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(username)
            .get(const GetOptions(source: Source.serverAndCache));
        
        print('Sorgu başarılı. Döküman var mı: ${docSnapshot.exists}');
        
        return !docSnapshot.exists;
        
      } on FirebaseException catch (e) {
        print('Firebase hatası (deneme ${i + 1}): ${e.code} - ${e.message}');
        
        if (e.code == 'unavailable' && i < 2) {
          // Bağlantı hatası, tekrar dene
          await Future.delayed(Duration(seconds: i + 1));
          continue;
        }
        
        // Son deneme veya farklı hata
        // Güvenlik açısından müsait kabul etme
        if (e.code == 'permission-denied') {
          print('İzin hatası - Rules kontrol edin');
          return false;
        }
        
        // Bağlantı sorunu varsa kullanıcının kayıt olmasına izin ver
        // Sonra kontrol edilebilir
        return true;
      } catch (e) {
        print('Beklenmeyen hata: $e');
        return true; // Kullanıcının kayıt olmasına izin ver
      }
    }
    
    return true; // Tüm denemeler başarısız, yine de izin ver
  }

  // Kullanıcı adını kaydet
  static Future<bool> reserveUsername(String username, String userId) async {
    try {
      username = username.toLowerCase();
      
      // Batch write kullan (daha güvenilir)
      final batch = FirebaseFirestore.instance.batch();
      
      // Username dökümanı
      final usernameRef = FirebaseFirestore.instance
          .collection('usernames')
          .doc(username);
      
      batch.set(usernameRef, {
        'userId': userId,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // User dökümanını güncelle
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      
      batch.update(userRef, {
        'username': username,
      });
      
      // Batch'i commit et
      await batch.commit();
      
      print('Username başarıyla kaydedildi: $username');
      return true;
      
    } catch (e) {
      print('Username kayıt hatası: $e');
      return false;
    }
  }

  // Kullanıcı adı önerileri
  static List<String> generateSuggestions(String name) {
    final suggestions = <String>[];
    
    // İsmi temizle
    String cleanName = name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Türkçe karakterleri değiştir
    cleanName = cleanName
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    
    if (cleanName.length >= 3) {
      suggestions.add(cleanName);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      suggestions.add('${cleanName}${timestamp % 1000}');
      suggestions.add('${cleanName}_${timestamp % 100}');
      suggestions.add('${cleanName}${DateTime.now().year}');
      
      // İlk ismi kullan
      final parts = name.toLowerCase().split(' ');
      if (parts.length > 1 && parts[0].length >= 3) {
        final firstName = parts[0].replaceAll(RegExp(r'[^a-z]'), '');
        suggestions.add(firstName);
        suggestions.add('${firstName}_${timestamp % 1000}');
      }
    }
    
    return suggestions.where((s) => s.length >= 3 && s.length <= 20).take(5).toList();
  }
}