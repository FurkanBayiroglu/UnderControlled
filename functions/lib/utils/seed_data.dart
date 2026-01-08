import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class SeedData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();
  
  // ============================================
  // 30 TEST KULLANICISI
  // ============================================
  
  static final List<Map<String, dynamic>> _sampleUsers = [
    {'name': 'Ahmet Yılmaz', 'username': 'ahmet_yilmaz', 'bio': 'Yazılımcı | Oyun sever 🎮'},
    {'name': 'Elif Kaya', 'username': 'elif.kaya', 'bio': 'Fotoğrafçı 📷 | Gezgin ✈️'},
    {'name': 'Mehmet Demir', 'username': 'mehmet_d', 'bio': 'Fitness tutkunu 💪'},
    {'name': 'Zeynep Aksoy', 'username': 'zeynep.aksoy', 'bio': 'Kitap kurdu 📚'},
    {'name': 'Can Öztürk', 'username': 'can_ozturk', 'bio': 'Müzisyen 🎸 | Prodüktör'},
    {'name': 'Selin Yıldız', 'username': 'selin.yildiz', 'bio': 'Yoga eğitmeni 🧘‍♀️'},
    {'name': 'Burak Şahin', 'username': 'burak_sahin', 'bio': 'E-spor oyuncusu 🏆'},
    {'name': 'Ayşe Çelik', 'username': 'ayse.celik', 'bio': 'Aşçı 👨‍🍳 | Yemek blogger'},
    {'name': 'Emre Koç', 'username': 'emre_koc', 'bio': 'Teknoloji meraklısı 🖥️'},
    {'name': 'Deniz Arslan', 'username': 'deniz.arslan', 'bio': 'Film eleştirmeni 🎬'},
    {'name': 'Cem Yılmazer', 'username': 'cem_y', 'bio': 'Startup founder 🚀'},
    {'name': 'İrem Polat', 'username': 'irem.polat', 'bio': 'Dijital sanatçı 🎨'},
    {'name': 'Kaan Erdoğan', 'username': 'kaan_e', 'bio': 'Basketbol | NBA fan 🏀'},
    {'name': 'Melis Güneş', 'username': 'melis.gunes', 'bio': 'Dil öğretmeni 🌍'},
    {'name': 'Oğuz Han', 'username': 'oguz_han', 'bio': 'Kripto yatırımcısı 💰'},
    {'name': 'Pınar Aydın', 'username': 'pinar.aydin', 'bio': 'Moda tasarımcısı 👗'},
    {'name': 'Serkan Tekin', 'username': 'serkan_t', 'bio': 'Otomobil tutkunu 🚗'},
    {'name': 'Tuğba Eren', 'username': 'tugba.eren', 'bio': 'Veteriner 🐾'},
    {'name': 'Umut Kara', 'username': 'umut_kara', 'bio': 'Stand-up komedyen 😂'},
    {'name': 'Yasemin Öz', 'username': 'yasemin.oz', 'bio': 'Podcast yapımcısı 🎙️'},
    {'name': 'Ali Vural', 'username': 'ali_vural', 'bio': 'Futbol fanatiği ⚽'},
    {'name': 'Beren Sağlam', 'username': 'beren.s', 'bio': 'Anime lover 🌸'},
    {'name': 'Cenk Akar', 'username': 'cenk_akar', 'bio': 'DJ | Müzik prodüktörü 🎵'},
    {'name': 'Dilan Yurt', 'username': 'dilan.yurt', 'bio': 'Seyahat blogger ✈️'},
    {'name': 'Efe Şimşek', 'username': 'efe_simsek', 'bio': 'Chess master ♟️'},
    {'name': 'Fulya Tan', 'username': 'fulya.tan', 'bio': 'Pilates eğitmeni'},
    {'name': 'Gökhan Aslan', 'username': 'gokhan_a', 'bio': 'Full-stack developer 💻'},
    {'name': 'Hande Uzun', 'username': 'hande.uzun', 'bio': 'İç mimar 🏠'},
    {'name': 'İlker Doğan', 'username': 'ilker_d', 'bio': 'Dağcı 🏔️ | Outdoor'},
    {'name': 'Jale Korkmaz', 'username': 'jale.k', 'bio': 'Çikolata ustası 🍫'},
  ];

  // ============================================
  // 66 ÖRNEK ODA
  // ============================================
  
  static final List<Map<String, dynamic>> _sampleRooms = [
    // SPOR & FITNESS (8 oda)
    {'name': 'Sabah Koşusu Grubu 🏃', 'description': 'Her sabah 07:00\'de buluşup koşuyoruz', 'category': 'sports', 'maxParticipants': 15},
    {'name': 'Halı Saha Maçı ⚽', 'description': 'Akşam 19:00 maç var, 2 kişi lazım!', 'category': 'sports', 'maxParticipants': 14},
    {'name': 'Basketbol Pickup Game 🏀', 'description': 'Hafta sonu basket oynuyoruz', 'category': 'sports', 'maxParticipants': 10},
    {'name': 'Fitness Motivasyon 💪', 'description': 'Birlikte spor yapıp motive oluyoruz', 'category': 'fitness', 'maxParticipants': 20},
    {'name': 'Gym Buddy Arıyorum', 'description': 'Kadıköy\'de gym arkadaşı lazım', 'category': 'fitness', 'maxParticipants': 4},
    {'name': 'Yoga & Meditasyon 🧘', 'description': 'Huzurlu bir ortamda yoga yapıyoruz', 'category': 'yoga', 'maxParticipants': 12},
    {'name': 'Dans Gecesi 💃', 'description': 'Salsa ve bachata öğreniyoruz', 'category': 'dance', 'maxParticipants': 16},
    {'name': 'Doğa Yürüyüşü 🏕️', 'description': 'Hafta sonu Belgrad Ormanı trekking', 'category': 'outdoor', 'maxParticipants': 12},
    
    // OYUN (10 oda)
    {'name': 'Valorant Ranked Takımı 🎮', 'description': 'Diamond+ ranked oynuyoruz', 'category': 'gaming', 'maxParticipants': 5},
    {'name': 'FIFA 24 Turnuvası', 'description': 'Haftalık turnuva, ödüllü!', 'category': 'gaming', 'maxParticipants': 16},
    {'name': 'Minecraft Server 🏗️', 'description': 'Survival dünyamıza katıl', 'category': 'gaming', 'maxParticipants': 20},
    {'name': 'GTA RP Topluluğu', 'description': 'Roleplay sunucumuz açıldı', 'category': 'gaming', 'maxParticipants': 32},
    {'name': 'CS2 5v5 Maç', 'description': 'Akşam 21:00 maç var', 'category': 'gaming', 'maxParticipants': 10},
    {'name': 'Masa Oyunları Gecesi 🎲', 'description': 'Catan, Monopoly, UNO', 'category': 'board_games', 'maxParticipants': 8},
    {'name': 'D&D Kampanyası', 'description': 'Yeni macera başlıyor!', 'category': 'board_games', 'maxParticipants': 6},
    {'name': 'Satranç Turnuvası ♟️', 'description': 'Online satranç turnuvası', 'category': 'board_games', 'maxParticipants': 16},
    {'name': 'League of Legends Clash 🏆', 'description': 'Clash için takım arıyoruz', 'category': 'esports', 'maxParticipants': 5},
    {'name': 'E-Spor İzleme Partisi', 'description': 'Worlds finalini birlikte izleyelim', 'category': 'esports', 'maxParticipants': 30},
    
    // MÜZİK & SANAT (8 oda)
    {'name': 'Gitar Çalışma Odası 🎸', 'description': 'Birlikte gitar öğreniyoruz', 'category': 'music', 'maxParticipants': 12},
    {'name': 'Jam Session', 'description': 'Canlı müzik yapıyoruz', 'category': 'music', 'maxParticipants': 8},
    {'name': 'Spotify Playlist Paylaşımı 🎵', 'description': 'En iyi playlistleri keşfediyoruz', 'category': 'music', 'maxParticipants': 50},
    {'name': 'Dijital Sanat Atölyesi 🎨', 'description': 'Procreate ve Photoshop', 'category': 'art', 'maxParticipants': 15},
    {'name': 'Çizim Challenge', 'description': 'Günlük çizim challenge', 'category': 'art', 'maxParticipants': 25},
    {'name': 'Fotoğraf Gezileri 📷', 'description': 'Hafta sonu fotoğraf çekimi', 'category': 'photography', 'maxParticipants': 10},
    {'name': 'Street Photography', 'description': 'Sokak fotoğrafçılığı', 'category': 'photography', 'maxParticipants': 8},
    {'name': 'Lightroom Editing', 'description': 'Fotoğraf düzenleme ipuçları', 'category': 'photography', 'maxParticipants': 20},
    
    // EĞİTİM (8 oda)
    {'name': 'YKS Çalışma Grubu 📚', 'description': 'Birlikte ders çalışıyoruz', 'category': 'study', 'maxParticipants': 25},
    {'name': 'KPSS Hazırlık', 'description': 'KPSS\'ye birlikte hazırlanıyoruz', 'category': 'study', 'maxParticipants': 30},
    {'name': 'Pomodoro Çalışma', 'description': '25 dk çalış, 5 dk mola', 'category': 'study', 'maxParticipants': 20},
    {'name': 'İngilizce Konuşma Kulübü 🌍', 'description': 'Speaking practice', 'category': 'language', 'maxParticipants': 10},
    {'name': 'Almanca Öğreniyoruz', 'description': 'A1-B1 seviye Almanca', 'category': 'language', 'maxParticipants': 12},
    {'name': 'Flutter Öğreniyoruz 💻', 'description': 'Sıfırdan Flutter ve Dart', 'category': 'coding', 'maxParticipants': 20},
    {'name': 'Python Başlangıç', 'description': 'Python\'a giriş kursu', 'category': 'coding', 'maxParticipants': 25},
    {'name': 'Kitap Kulübü 📖', 'description': 'Ayda 2 kitap okuyoruz', 'category': 'reading', 'maxParticipants': 15},
    
    // SOSYAL (8 oda)
    {'name': 'Gece Sohbetleri 🌙', 'description': 'Gece kuşları için sohbet', 'category': 'chat', 'maxParticipants': 30},
    {'name': 'Random Sohbet', 'description': 'Her konuda sohbet', 'category': 'chat', 'maxParticipants': 50},
    {'name': '20\'li Yaşlar Kulübü', 'description': '20-29 yaş arası sohbet', 'category': 'chat', 'maxParticipants': 40},
    {'name': 'Gündem Tartışmaları 🗣️', 'description': 'Saygılı fikir alışverişi', 'category': 'debate', 'maxParticipants': 20},
    {'name': 'Felsefe Sohbetleri', 'description': 'Derin düşünceler', 'category': 'debate', 'maxParticipants': 15},
    {'name': 'Kahve & Sohbet ☕', 'description': 'Sabah kahvesi eşliğinde', 'category': 'coffee', 'maxParticipants': 12},
    {'name': 'Networking Event 🤝', 'description': 'Profesyonel networking', 'category': 'chat', 'maxParticipants': 25},
    {'name': 'Startup Founders', 'description': 'Girişimciler buluşuyor', 'category': 'chat', 'maxParticipants': 20},
    
    // FİLM & MEDYA (6 oda)
    {'name': 'Film Gecesi 🎬', 'description': 'Her Cuma birlikte film', 'category': 'movie', 'maxParticipants': 25},
    {'name': 'Korku Filmi Maratonu', 'description': 'Cesaretin varsa gel 👻', 'category': 'movie', 'maxParticipants': 15},
    {'name': 'Oscar Tahminleri', 'description': 'Oscar adaylarını tartışıyoruz', 'category': 'movie', 'maxParticipants': 20},
    {'name': 'Anime İzleme Grubu 🌸', 'description': 'Yeni sezon animeler', 'category': 'anime', 'maxParticipants': 20},
    {'name': 'One Piece Fan Club', 'description': 'Nakama arıyoruz!', 'category': 'anime', 'maxParticipants': 30},
    {'name': 'Podcast Önerileri 🎙️', 'description': 'En iyi podcastler', 'category': 'chat', 'maxParticipants': 25},
    
    // YEMEK (4 oda)
    {'name': 'Yemek Tarifleri 🍕', 'description': 'Tariflerimizi paylaşıyoruz', 'category': 'food', 'maxParticipants': 30},
    {'name': 'Restoran Önerileri', 'description': 'İstanbul\'un en iyi mekanları', 'category': 'food', 'maxParticipants': 40},
    {'name': 'Aşçılık Atölyesi 👨‍🍳', 'description': 'Canlı yemek yapıyoruz', 'category': 'cooking', 'maxParticipants': 15},
    {'name': 'Vegan Mutfak 🥗', 'description': 'Vegan tarifler', 'category': 'cooking', 'maxParticipants': 20},
    
    // SEYAHAT (4 oda)
    {'name': 'Seyahat Planlama ✈️', 'description': 'Tatil planları ve öneriler', 'category': 'travel', 'maxParticipants': 25},
    {'name': 'Backpacker Türkiye', 'description': 'Sırt çantalı gezginler', 'category': 'travel', 'maxParticipants': 20},
    {'name': 'Kamp Severler 🏕️', 'description': 'Kamp yerleri ve ipuçları', 'category': 'outdoor', 'maxParticipants': 18},
    {'name': 'Avrupa Turu Planlama', 'description': 'Interrail deneyimleri', 'category': 'travel', 'maxParticipants': 15},
    
    // TEKNOLOJİ (6 oda)
    {'name': 'Teknoloji Haberleri 🖥️', 'description': 'Son teknoloji gelişmeleri', 'category': 'tech', 'maxParticipants': 30},
    {'name': 'iPhone vs Android', 'description': 'Efsane tartışma 😄', 'category': 'tech', 'maxParticipants': 40},
    {'name': 'Kripto & Yatırım 💰', 'description': 'Kripto stratejileri', 'category': 'crypto', 'maxParticipants': 25},
    {'name': 'NFT Koleksiyoncuları', 'description': 'NFT dünyası', 'category': 'crypto', 'maxParticipants': 20},
    {'name': 'AI ve ChatGPT', 'description': 'Yapay zeka sohbetleri', 'category': 'tech', 'maxParticipants': 35},
    {'name': 'Web3 Developers', 'description': 'Blockchain geliştirme', 'category': 'coding', 'maxParticipants': 15},
    
    // DİĞER (6 oda)
    {'name': 'Kedi Severler 🐱', 'description': 'Kedi sahipleri burada!', 'category': 'pets', 'maxParticipants': 30},
    {'name': 'Köpek Parkı Buluşması 🐕', 'description': 'Köpeklerimizle parkta', 'category': 'pets', 'maxParticipants': 15},
    {'name': 'Araba Tutkunları 🚗', 'description': 'Otomobil ve modifiye', 'category': 'cars', 'maxParticipants': 25},
    {'name': 'Motorsiklet Grubu 🏍️', 'description': 'Hafta sonu sürüşleri', 'category': 'cars', 'maxParticipants': 12},
    {'name': 'Moda & Stil 👗', 'description': 'Trend ve kombinler', 'category': 'fashion', 'maxParticipants': 30},
    {'name': 'Thrift Shopping', 'description': 'İkinci el alışveriş', 'category': 'fashion', 'maxParticipants': 20},
  ];

  // ============================================
  // ANA FONKSİYONLAR
  // ============================================

  /// 🚀 TAM KURULUM - Kullanıcılar + Odalar + Takipleşmeler
  static Future<void> createAllSampleData() async {
    try {
      // 1. Kullanıcıları oluştur
      final userIds = await createSampleUsers();
      
      // 2. Odaları oluştur
      await createSampleRooms(userIds: userIds);
      
      // 3. Takipleşmeleri oluştur
      await createRandomFollows(userIds);
      
      print('🎉 Tam kurulum tamamlandı: 30 kullanıcı, 66 oda!');
    } catch (e) {
      print('❌ Hata: $e');
      rethrow;
    }
  }

  /// Test kullanıcıları oluşturur
  static Future<List<String>> createSampleUsers() async {
    final List<String> userIds = [];
    
    // Batch'leri 500'lük parçalara böl (Firestore limiti)
    final batch = _firestore.batch();
    
    for (var user in _sampleUsers) {
      final docRef = _firestore.collection('users').doc();
      userIds.add(docRef.id);
      
      batch.set(docRef, {
        ...user,
        'email': '${user['username']}@test.com',
        'createdAt': FieldValue.serverTimestamp(),
        'followers': [],
        'following': [],
        'followRequests': [],
        'sentRequests': [],
        'isPrivate': _random.nextDouble() < 0.2, // %20 gizli hesap
      });
    }
    
    await batch.commit();
    print('✅ ${_sampleUsers.length} test kullanıcısı oluşturuldu!');
    return userIds;
  }

  /// Örnek odalar oluşturur
  static Future<void> createSampleRooms({List<String>? userIds}) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
    
    // Kullanıcı listesini hazırla
    List<String> availableUsers = userIds ?? [];
    if (availableUsers.isEmpty) {
      final usersSnapshot = await _firestore.collection('users').limit(30).get();
      availableUsers = usersSnapshot.docs.map((d) => d.id).toList();
    }
    
    if (!availableUsers.contains(currentUserId)) {
      availableUsers.add(currentUserId);
    }
    
    final batch = _firestore.batch();
    
    for (var room in _sampleRooms) {
      final docRef = _firestore.collection('rooms').doc();
      
      // Rastgele katılımcı sayısı
      final maxP = room['maxParticipants'] as int;
      final participantCount = _random.nextInt((maxP * 0.8).round()) + 1;
      
      // Rastgele kullanıcıları seç
      final shuffledUsers = List<String>.from(availableUsers)..shuffle();
      final participants = shuffledUsers.take(participantCount).toList();
      
      batch.set(docRef, {
        ...room,
        'createdBy': participants.isNotEmpty ? participants.first : currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': participants,
        'participantCount': participants.length,
        'isActive': true,
        'isPrivate': false,
      });
    }
    
    await batch.commit();
    print('✅ ${_sampleRooms.length} örnek oda oluşturuldu!');
  }

  /// Rastgele takipleşmeler oluşturur
  static Future<void> createRandomFollows(List<String> userIds) async {
    if (userIds.length < 2) return;
    
    for (var userId in userIds) {
      // Her kullanıcı 5-15 kişiyi takip etsin
      final followCount = _random.nextInt(11) + 5;
      final otherUsers = userIds.where((id) => id != userId).toList()..shuffle();
      final toFollow = otherUsers.take(followCount).toList();
      
      await _firestore.collection('users').doc(userId).update({
        'following': toFollow,
      });
      
      // Takip edilenlerin followers'ına ekle
      for (var followedId in toFollow) {
        await _firestore.collection('users').doc(followedId).update({
          'followers': FieldValue.arrayUnion([userId]),
        });
      }
    }
    
    print('✅ Rastgele takipleşmeler oluşturuldu!');
  }

  /// Sadece odaları oluşturur (kullanıcı yoksa)
  static Future<void> createSampleRoomsOnly() async {
    await createSampleRooms();
  }

  /// Tüm odaları siler
  static Future<void> deleteAllRooms() async {
    final rooms = await _firestore.collection('rooms').get();
    final batch = _firestore.batch();
    for (var doc in rooms.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    print('🗑️ Tüm odalar silindi!');
  }

  /// Tüm test verilerini siler
  static Future<void> deleteAllTestData() async {
    // Odaları sil
    await deleteAllRooms();
    
    // Test kullanıcılarını sil (@test.com)
    final users = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    for (var doc in users.docs) {
      final email = doc.data()['email'] as String?;
      if (email != null && email.endsWith('@test.com')) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
    print('🗑️ Tüm test verileri silindi!');
  }

  /// İstatistikleri getirir
  static Future<Map<String, int>> getStats() async {
    final roomCount = await _firestore.collection('rooms').count().get();
    final userCount = await _firestore.collection('users').count().get();
    
    return {
      'rooms': roomCount.count ?? 0,
      'users': userCount.count ?? 0,
    };
  }
}