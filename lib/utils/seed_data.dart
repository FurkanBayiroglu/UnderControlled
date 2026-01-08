import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class SeedData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // ============================================
  // 50 FAKE KULLANICI
  // ============================================
  
  static final List<Map<String, dynamic>> _sampleUsers = [
    {'name': 'Ahmet Yılmaz', 'username': 'ahmet_yilmaz', 'bio': 'Yazılımcı | Oyun sever 🎮', 'email': 'ahmet@test.com'},
    {'name': 'Elif Kaya', 'username': 'elif_kaya', 'bio': 'Fotoğrafçı 📷 | Gezgin ✈️', 'email': 'elif@test.com'},
    {'name': 'Mehmet Demir', 'username': 'mehmet_demir', 'bio': 'Fitness tutkunu 💪', 'email': 'mehmet@test.com'},
    {'name': 'Zeynep Aksoy', 'username': 'zeynep_aksoy', 'bio': 'Kitap kurdu 📚', 'email': 'zeynep@test.com'},
    {'name': 'Can Öztürk', 'username': 'can_ozturk', 'bio': 'Müzisyen 🎸 | Prodüktör', 'email': 'can@test.com'},
    {'name': 'Selin Yıldız', 'username': 'selin_yildiz', 'bio': 'Yoga eğitmeni 🧘‍♀️', 'email': 'selin@test.com'},
    {'name': 'Burak Şahin', 'username': 'burak_sahin', 'bio': 'E-spor oyuncusu 🏆', 'email': 'burak@test.com'},
    {'name': 'Ayşe Çelik', 'username': 'ayse_celik', 'bio': 'Aşçı 👨‍🍳 | Yemek blogger', 'email': 'ayse@test.com'},
    {'name': 'Emre Koç', 'username': 'emre_koc', 'bio': 'Teknoloji meraklısı 🖥️', 'email': 'emre@test.com'},
    {'name': 'Deniz Arslan', 'username': 'deniz_arslan', 'bio': 'Film eleştirmeni 🎬', 'email': 'deniz@test.com'},
    {'name': 'Cem Yılmazer', 'username': 'cem_yilmazer', 'bio': 'Startup founder 🚀', 'email': 'cem@test.com'},
    {'name': 'İrem Polat', 'username': 'irem_polat', 'bio': 'Dijital sanatçı 🎨', 'email': 'irem@test.com'},
    {'name': 'Kaan Erdoğan', 'username': 'kaan_erdogan', 'bio': 'Basketbol | NBA fan 🏀', 'email': 'kaan@test.com'},
    {'name': 'Melis Güneş', 'username': 'melis_gunes', 'bio': 'Dil öğretmeni 🌍', 'email': 'melis@test.com'},
    {'name': 'Oğuz Han', 'username': 'oguz_han', 'bio': 'Kripto yatırımcısı 💰', 'email': 'oguz@test.com'},
    {'name': 'Pınar Aydın', 'username': 'pinar_aydin', 'bio': 'Moda tasarımcısı 👗', 'email': 'pinar@test.com'},
    {'name': 'Serkan Tekin', 'username': 'serkan_tekin', 'bio': 'Otomobil tutkunu 🚗', 'email': 'serkan@test.com'},
    {'name': 'Tuğba Eren', 'username': 'tugba_eren', 'bio': 'Veteriner 🐾', 'email': 'tugba@test.com'},
    {'name': 'Umut Kara', 'username': 'umut_kara', 'bio': 'Stand-up komedyen 😂', 'email': 'umut@test.com'},
    {'name': 'Yasemin Öz', 'username': 'yasemin_oz', 'bio': 'Podcast yapımcısı 🎙️', 'email': 'yasemin@test.com'},
    {'name': 'Ali Vural', 'username': 'ali_vural', 'bio': 'Futbol fanatiği ⚽', 'email': 'ali@test.com'},
    {'name': 'Beren Sağlam', 'username': 'beren_saglam', 'bio': 'Anime lover 🌸', 'email': 'beren@test.com'},
    {'name': 'Cenk Akar', 'username': 'cenk_akar', 'bio': 'DJ | Müzik prodüktörü 🎵', 'email': 'cenk@test.com'},
    {'name': 'Dilan Yurt', 'username': 'dilan_yurt', 'bio': 'Seyahat blogger ✈️', 'email': 'dilan@test.com'},
    {'name': 'Efe Şimşek', 'username': 'efe_simsek', 'bio': 'Chess master ♟️', 'email': 'efe@test.com'},
    {'name': 'Fulya Tan', 'username': 'fulya_tan', 'bio': 'Pilates eğitmeni', 'email': 'fulya@test.com'},
    {'name': 'Gökhan Aslan', 'username': 'gokhan_aslan', 'bio': 'Full-stack developer 💻', 'email': 'gokhan@test.com'},
    {'name': 'Hande Uzun', 'username': 'hande_uzun', 'bio': 'İç mimar 🏠', 'email': 'hande@test.com'},
    {'name': 'İlker Doğan', 'username': 'ilker_dogan', 'bio': 'Dağcı 🏔️ | Outdoor', 'email': 'ilker@test.com'},
    {'name': 'Jale Korkmaz', 'username': 'jale_korkmaz', 'bio': 'Çikolata ustası 🍫', 'email': 'jale@test.com'},
    {'name': 'Kemal Yavuz', 'username': 'kemal_yavuz', 'bio': 'Grafik tasarımcı ✏️', 'email': 'kemal@test.com'},
    {'name': 'Lale Şen', 'username': 'lale_sen', 'bio': 'Psikolojik danışman 🧠', 'email': 'lale@test.com'},
    {'name': 'Murat Kılıç', 'username': 'murat_kilic', 'bio': 'Barista ☕', 'email': 'murat@test.com'},
    {'name': 'Nazlı Yurt', 'username': 'nazli_yurt', 'bio': 'Vegan aktivist 🌱', 'email': 'nazli@test.com'},
    {'name': 'Onur Acar', 'username': 'onur_acar', 'bio': 'Arkeolog 🏺', 'email': 'onur@test.com'},
    {'name': 'Özge Aksoy', 'username': 'ozge_aksoy', 'bio': 'Blogger | Influencer 📱', 'email': 'ozge@test.com'},
    {'name': 'Kerem Yılmaz', 'username': 'kerem_yilmaz', 'bio': 'Siber güvenlik uzmanı 🔐', 'email': 'kerem@test.com'},
    {'name': 'Seda Şahin', 'username': 'seda_sahin', 'bio': 'Dans eğitmeni 💃', 'email': 'seda@test.com'},
    {'name': 'Tolga Demir', 'username': 'tolga_demir', 'bio': 'Video editor 🎥', 'email': 'tolga@test.com'},
    {'name': 'Ufuk Polat', 'username': 'ufuk_polat', 'bio': 'Motosiklet tutkunu 🏍️', 'email': 'ufuk@test.com'},
    {'name': 'Volkan Kaya', 'username': 'volkan_kaya', 'bio': 'Barmen 🍸', 'email': 'volkan@test.com'},
    {'name': 'Yağmur Arslan', 'username': 'yagmur_arslan', 'bio': 'Yoga & Meditasyon 🕉️', 'email': 'yagmur@test.com'},
    {'name': 'Zafer Koç', 'username': 'zafer_koc', 'bio': 'E-ticaret girişimcisi 📦', 'email': 'zafer@test.com'},
    {'name': 'Aslı Güneş', 'username': 'asli_gunes', 'bio': 'Müzik öğretmeni 🎼', 'email': 'asli@test.com'},
    {'name': 'Barış Yıldırım', 'username': 'baris_yildirim', 'bio': 'Freelance yazılımcı 💻', 'email': 'baris@test.com'},
    {'name': 'Ceren Öztürk', 'username': 'ceren_ozturk', 'bio': 'Sosyal medya uzmanı 📲', 'email': 'ceren@test.com'},
    {'name': 'Doruk Şen', 'username': 'doruk_sen', 'bio': 'Oyuncu | Tiyatro 🎭', 'email': 'doruk@test.com'},
    {'name': 'Esra Çelik', 'username': 'esra_celik', 'bio': 'Diş hekimi 🦷', 'email': 'esra@test.com'},
    {'name': 'Fırat Kara', 'username': 'firat_kara', 'bio': 'Muhasebeci 📊', 'email': 'firat@test.com'},
    {'name': 'Gül Demir', 'username': 'gul_demir', 'bio': 'Eczacı 💊', 'email': 'gul@test.com'},
  ];

  // ============================================
  // 70 ÖRNEK ODA
  // ============================================
  
  static final List<Map<String, dynamic>> _sampleRooms = [
    // SPOR (10 oda)
    {'name': 'Sabah Koşusu Grubu 🏃', 'description': 'Her sabah 07:00\'de buluşup koşuyoruz', 'category': 'sports', 'maxMembers': 15},
    {'name': 'Halı Saha Maçı ⚽', 'description': 'Akşam 19:00 maç var, 2 kişi lazım!', 'category': 'sports', 'maxMembers': 14},
    {'name': 'Basketbol Pickup Game 🏀', 'description': 'Hafta sonu basket oynuyoruz', 'category': 'sports', 'maxMembers': 10},
    {'name': 'Fitness Motivasyon 💪', 'description': 'Birlikte spor yapıp motive oluyoruz', 'category': 'sports', 'maxMembers': 20},
    {'name': 'Gym Buddy Arıyorum', 'description': 'Kadıköy\'de gym arkadaşı lazım', 'category': 'sports', 'maxMembers': 4},
    {'name': 'Yoga & Meditasyon 🧘', 'description': 'Huzurlu bir ortamda yoga yapıyoruz', 'category': 'sports', 'maxMembers': 12},
    {'name': 'Dans Gecesi 💃', 'description': 'Salsa ve bachata öğreniyoruz', 'category': 'sports', 'maxMembers': 16},
    {'name': 'Doğa Yürüyüşü 🏕️', 'description': 'Hafta sonu Belgrad Ormanı trekking', 'category': 'sports', 'maxMembers': 12},
    {'name': 'Tenis Partner Arıyorum 🎾', 'description': 'Hafta içi tenis oynayacak partner', 'category': 'sports', 'maxMembers': 4},
    {'name': 'Bisiklet Turu 🚴', 'description': 'Pazar sabahı sahil turu', 'category': 'sports', 'maxMembers': 15},
    
    // OYUN (12 oda)
    {'name': 'Valorant Ranked Takımı 🎮', 'description': 'Diamond+ ranked oynuyoruz', 'category': 'gaming', 'maxMembers': 5},
    {'name': 'FIFA 24 Turnuvası', 'description': 'Haftalık turnuva, ödüllü!', 'category': 'gaming', 'maxMembers': 16},
    {'name': 'Minecraft Server 🏗️', 'description': 'Survival dünyamıza katıl', 'category': 'gaming', 'maxMembers': 20},
    {'name': 'GTA RP Topluluğu', 'description': 'Roleplay sunucumuz açıldı', 'category': 'gaming', 'maxMembers': 32},
    {'name': 'CS2 5v5 Maç', 'description': 'Akşam 21:00 maç var', 'category': 'gaming', 'maxMembers': 10},
    {'name': 'Masa Oyunları Gecesi 🎲', 'description': 'Catan, Monopoly, UNO', 'category': 'gaming', 'maxMembers': 8},
    {'name': 'D&D Kampanyası', 'description': 'Yeni macera başlıyor!', 'category': 'gaming', 'maxMembers': 6},
    {'name': 'Satranç Turnuvası ♟️', 'description': 'Online satranç turnuvası', 'category': 'gaming', 'maxMembers': 16},
    {'name': 'League of Legends Clash 🏆', 'description': 'Clash için takım arıyoruz', 'category': 'gaming', 'maxMembers': 5},
    {'name': 'E-Spor İzleme Partisi', 'description': 'Worlds finalini birlikte izleyelim', 'category': 'gaming', 'maxMembers': 30},
    {'name': 'Mobile Legends Squad', 'description': 'Rank kasmak için takım', 'category': 'gaming', 'maxMembers': 5},
    {'name': 'Fortnite Duo Partner', 'description': 'Arena oynayacak duo lazım', 'category': 'gaming', 'maxMembers': 4},
    
    // MÜZİK (8 oda)
    {'name': 'Gitar Çalışma Odası 🎸', 'description': 'Birlikte gitar öğreniyoruz', 'category': 'music', 'maxMembers': 12},
    {'name': 'Jam Session', 'description': 'Canlı müzik yapıyoruz', 'category': 'music', 'maxMembers': 8},
    {'name': 'Spotify Playlist Paylaşımı 🎵', 'description': 'En iyi playlistleri keşfediyoruz', 'category': 'music', 'maxMembers': 50},
    {'name': 'Rock Müzik Severler 🤘', 'description': 'Rock ve metal konuşuyoruz', 'category': 'music', 'maxMembers': 25},
    {'name': 'Rap & Hip-Hop Türkiye', 'description': 'Türkçe rap tartışmaları', 'category': 'music', 'maxMembers': 30},
    {'name': 'Klasik Müzik Kulübü', 'description': 'Klasik müzik dinleme seansları', 'category': 'music', 'maxMembers': 15},
    {'name': 'DJ Mixing Workshop', 'description': 'DJ olmayı öğreniyoruz', 'category': 'music', 'maxMembers': 10},
    {'name': 'Şarkı Sözü Yazıyoruz ✍️', 'description': 'Birlikte şarkı yazalım', 'category': 'music', 'maxMembers': 8},
    
    // YEMEK (8 oda)
    {'name': 'Yemek Tarifleri 🍕', 'description': 'Tariflerimizi paylaşıyoruz', 'category': 'food', 'maxMembers': 30},
    {'name': 'Restoran Önerileri', 'description': 'İstanbul\'un en iyi mekanları', 'category': 'food', 'maxMembers': 40},
    {'name': 'Aşçılık Atölyesi 👨‍🍳', 'description': 'Canlı yemek yapıyoruz', 'category': 'food', 'maxMembers': 15},
    {'name': 'Vegan Mutfak 🥗', 'description': 'Vegan tarifler', 'category': 'food', 'maxMembers': 20},
    {'name': 'Kahve Tutkunları ☕', 'description': 'En iyi kahveciler ve demleme', 'category': 'food', 'maxMembers': 25},
    {'name': 'Tatlı Yapımı 🍰', 'description': 'Pasta ve tatlı tarifleri', 'category': 'food', 'maxMembers': 18},
    {'name': 'Street Food İstanbul', 'description': 'Sokak lezzetleri turu', 'category': 'food', 'maxMembers': 12},
    {'name': 'Barbekü Severler 🍖', 'description': 'Mangal ve barbekü ipuçları', 'category': 'food', 'maxMembers': 20},
    
    // SOHBET (10 oda)
    {'name': 'Gece Sohbetleri 🌙', 'description': 'Gece kuşları için sohbet', 'category': 'chat', 'maxMembers': 30},
    {'name': 'Random Sohbet', 'description': 'Her konuda sohbet', 'category': 'chat', 'maxMembers': 50},
    {'name': '20\'li Yaşlar Kulübü', 'description': '20-29 yaş arası sohbet', 'category': 'chat', 'maxMembers': 40},
    {'name': 'Gündem Tartışmaları 🗣️', 'description': 'Saygılı fikir alışverişi', 'category': 'chat', 'maxMembers': 20},
    {'name': 'Felsefe Sohbetleri', 'description': 'Derin düşünceler', 'category': 'chat', 'maxMembers': 15},
    {'name': 'Kahve & Sohbet ☕', 'description': 'Sabah kahvesi eşliğinde', 'category': 'chat', 'maxMembers': 12},
    {'name': 'Networking Event 🤝', 'description': 'Profesyonel networking', 'category': 'chat', 'maxMembers': 25},
    {'name': 'Startup Founders', 'description': 'Girişimciler buluşuyor', 'category': 'chat', 'maxMembers': 20},
    {'name': 'Kitap Kulübü 📚', 'description': 'Ayda 2 kitap okuyoruz', 'category': 'chat', 'maxMembers': 15},
    {'name': 'Dil Değişimi 🌍', 'description': 'Türkçe-İngilizce pratik', 'category': 'chat', 'maxMembers': 16},
    
    // FİLM (8 oda)
    {'name': 'Film Gecesi 🎬', 'description': 'Her Cuma birlikte film', 'category': 'movie', 'maxMembers': 25},
    {'name': 'Korku Filmi Maratonu', 'description': 'Cesaretin varsa gel 👻', 'category': 'movie', 'maxMembers': 15},
    {'name': 'Oscar Tahminleri', 'description': 'Oscar adaylarını tartışıyoruz', 'category': 'movie', 'maxMembers': 20},
    {'name': 'Anime İzleme Grubu 🌸', 'description': 'Yeni sezon animeler', 'category': 'movie', 'maxMembers': 20},
    {'name': 'One Piece Fan Club', 'description': 'Nakama arıyoruz!', 'category': 'movie', 'maxMembers': 30},
    {'name': 'Marvel vs DC', 'description': 'Süper kahraman tartışmaları', 'category': 'movie', 'maxMembers': 35},
    {'name': 'K-Drama Severler 🇰🇷', 'description': 'Kore dizisi önerileri', 'category': 'movie', 'maxMembers': 25},
    {'name': 'Belgesel Kulübü', 'description': 'En iyi belgeseller', 'category': 'movie', 'maxMembers': 18},
    
    // TEKNOLOJİ (8 oda)
    {'name': 'Teknoloji Haberleri 🖥️', 'description': 'Son teknoloji gelişmeleri', 'category': 'technology', 'maxMembers': 30},
    {'name': 'iPhone vs Android', 'description': 'Efsane tartışma 😄', 'category': 'technology', 'maxMembers': 40},
    {'name': 'Kripto & Yatırım 💰', 'description': 'Kripto stratejileri', 'category': 'technology', 'maxMembers': 25},
    {'name': 'AI ve ChatGPT', 'description': 'Yapay zeka sohbetleri', 'category': 'technology', 'maxMembers': 35},
    {'name': 'Flutter Öğreniyoruz 💻', 'description': 'Sıfırdan Flutter ve Dart', 'category': 'technology', 'maxMembers': 20},
    {'name': 'Python Başlangıç', 'description': 'Python\'a giriş kursu', 'category': 'technology', 'maxMembers': 25},
    {'name': 'Web Development', 'description': 'Frontend ve backend', 'category': 'technology', 'maxMembers': 22},
    {'name': 'Cybersecurity 🔐', 'description': 'Siber güvenlik konuları', 'category': 'technology', 'maxMembers': 18},
    
    // SEYAHAT (6 oda)
    {'name': 'Seyahat Planlama ✈️', 'description': 'Tatil planları ve öneriler', 'category': 'travel', 'maxMembers': 25},
    {'name': 'Backpacker Türkiye', 'description': 'Sırt çantalı gezginler', 'category': 'travel', 'maxMembers': 20},
    {'name': 'Kamp Severler 🏕️', 'description': 'Kamp yerleri ve ipuçları', 'category': 'travel', 'maxMembers': 18},
    {'name': 'Avrupa Turu Planlama', 'description': 'Interrail deneyimleri', 'category': 'travel', 'maxMembers': 15},
    {'name': 'Kapadokya Gezisi 🎈', 'description': 'Balon turu organize ediyoruz', 'category': 'travel', 'maxMembers': 10},
    {'name': 'Ege Sahilleri', 'description': 'En güzel koylar', 'category': 'travel', 'maxMembers': 20},
  ];

  // ============================================
  // ANA FONKSİYON - HER ŞEYİ OLUŞTUR
  // ============================================

  /// 🚀 Kullanıcılar + Odalar + Takipleşmeler (FULL SETUP)
  static Future<void> seedEverything() async {
    try {
      print('🚀 Dummy data yükleniyor...');
      print('');
      
      // 1. Kullanıcıları oluştur
      print('👤 1/4: Kullanıcılar oluşturuluyor...');
      final userIds = await _createUsers();
      print('✅ ${userIds.length} kullanıcı oluşturuldu');
      
      // Firestore'un commit'i tamamlaması için bekle
      await Future.delayed(const Duration(seconds: 2));
      print('');
      
      // 2. Odaları oluştur
      print('🏠 2/4: Odalar oluşturuluyor...');
      final roomIds = await _createRooms(userIds);
      print('✅ ${_sampleRooms.length} oda oluşturuldu');
      
      // Firestore'un commit'i tamamlaması için bekle
      await Future.delayed(const Duration(seconds: 2));
      print('');
      
      // 3. Örnek mesajlar
      print('💬 3/4: Örnek mesajlar oluşturuluyor...');
      await _createSampleMessages(roomIds, userIds);
      print('✅ Örnek mesajlar oluşturuldu');
      
      await Future.delayed(const Duration(seconds: 1));
      print('');
      
      // 4. Takipleşmeler
      print('🤝 4/4: Takipleşmeler oluşturuluyor...');
      await _createFollows(userIds);
      print('✅ Takipleşmeler oluşturuldu');
      print('');
      
      print('🎉 TÜM DUMMY DATA BAŞARIYLA YÜKLENDİ!');
      print('📊 Özet:');
      print('   • ${userIds.length} kullanıcı');
      print('   • ${_sampleRooms.length} oda');
      print('   • Örnek mesajlar');
      print('   • Takipleşmeler aktif');
      
    } catch (e, stackTrace) {
      print('❌ Hata: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Sadece kullanıcıları oluşturur
  static Future<List<String>> _createUsers() async {
    final batch = _firestore.batch();
    final List<String> userIds = [];
    
    for (var user in _sampleUsers) {
      // Rastgele ID oluştur (gerçek Auth olmadan)
      final userId = 'user_${_random.nextInt(999999).toString().padLeft(6, '0')}';
      userIds.add(userId);
      
      final docRef = _firestore.collection('users').doc(userId);
      
      batch.set(docRef, {
        'name': user['name'],
        'username': user['username'],
        'email': user['email'],
        'bio': user['bio'],
        'photoURL': null, // Profil fotoğrafı yok
        'createdAt': FieldValue.serverTimestamp(),
        'followers': [],
        'following': [],
        'followRequests': [],
        'isPrivate': _random.nextDouble() < 0.2, // %20 özel profil
      });
    }
    
    await batch.commit();
    
    // Doğrulama: Kullanıcılar gerçekten oluşturuldu mu?
    print('📋 Oluşturulan kullanıcı ID\'leri:');
    for (var i = 0; i < userIds.length && i < 5; i++) {
      print('   ${i + 1}. ${userIds[i]}');
    }
    print('   ... (${userIds.length} kullanıcı)');
    
    return userIds;
  }

  /// Odaları oluşturur ve kullanıcıları dağıtır
  static Future<List<String>> _createRooms(List<String> userIds) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      print('⚠️ Kullanıcı giriş yapmamış! Sadece dummy kullanıcılarla devam ediliyor.');
    } else {
      print('✓ Current user: $currentUserId');
    }
    
    // Mevcut kullanıcıyı da listeye ekle
    if (currentUserId != null && !userIds.contains(currentUserId)) {
      userIds.add(currentUserId);
      print('✓ Current user listeye eklendi. Toplam: ${userIds.length} kullanıcı');
    }
    
    final batch = _firestore.batch();
    final List<String> roomIds = [];
    
    print('📋 İlk 3 oda örneği:');
    
    for (var i = 0; i < _sampleRooms.length; i++) {
      final room = _sampleRooms[i];
      final docRef = _firestore.collection('rooms').doc();
      roomIds.add(docRef.id);
      
      // Rastgele üye sayısı (max'ın %30-70'i arası)
      final maxM = room['maxMembers'] as int;
      final minMembers = (maxM * 0.3).round();
      final maxMembers = (maxM * 0.7).round();
      final memberCount = _random.nextInt(maxMembers - minMembers + 1) + minMembers;
      
      // Rastgele kullanıcıları seç
      final shuffledUsers = List<String>.from(userIds)..shuffle();
      List<String> members = shuffledUsers.take(memberCount.clamp(2, userIds.length)).toList();
      
      // Current user'ı MUTLAKA ekle
      if (currentUserId != null && !members.contains(currentUserId)) {
        members.insert(0, currentUserId);
      }
      
      // Oluşturanı current user yap, yoksa ilk üye
      final createdBy = currentUserId ?? members.first;
      
      // İlk 3 oda için debug
      if (i < 3) {
        print('   ${i + 1}. ${room['name']}');
        print('      Üye sayısı: ${members.length}');
        print('      İlk 3 üye: ${members.take(3).join(", ")}');
      }
      
      batch.set(docRef, {
        'name': room['name'],
        'description': room['description'],
        'category': room['category'],
        'maxMembers': room['maxMembers'],
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'members': members,
        'memberCount': members.length,
        'isActive': true,
        'isPrivate': _random.nextDouble() < 0.1, // %10 özel
      });
    }
    
    await batch.commit();
    return roomIds;
  }

  /// Rastgele takipleşmeler oluşturur (batch ile optimize edilmiş)
  static Future<void> _createFollows(List<String> userIds) async {
    try {
      // Her kullanıcı için following/followers hesapla
      final Map<String, List<String>> followingMap = {};
      final Map<String, List<String>> followersMap = {};
      
      // Initialize
      for (var userId in userIds) {
        followingMap[userId] = [];
        followersMap[userId] = [];
      }
      
      // Her kullanıcı için takip edilecekleri belirle
      for (var userId in userIds) {
        final followCount = _random.nextInt(6) + 3; // 3-8 kişi
        final otherUsers = userIds.where((id) => id != userId).toList()..shuffle();
        final toFollow = otherUsers.take(followCount).toList();
        
        followingMap[userId] = toFollow;
        
        // Takip edilenlerin followers listesine ekle
        for (var followedId in toFollow) {
          followersMap[followedId]?.add(userId);
        }
      }
      
      // Batch ile güncelle - set(merge: true) kullan
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;
      
      for (var userId in userIds) {
        final docRef = _firestore.collection('users').doc(userId);
        
        // update yerine set(merge: true) kullan - daha güvenli
        currentBatch.set(
          docRef, 
          {
            'following': followingMap[userId] ?? [],
            'followers': followersMap[userId] ?? [],
          },
          SetOptions(merge: true), // Var olan datayı korur
        );
        
        operationCount++;
        
        // Batch limiti 500
        if (operationCount >= 500) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
      }
      
      if (operationCount > 0) {
        batches.add(currentBatch);
      }
      
      // Tüm batch'leri commit et
      for (var batch in batches) {
        await batch.commit();
      }
      
      print('✓ ${userIds.length} kullanıcı için takipleşmeler oluşturuldu');
    } catch (e) {
      print('❌ Takipleşme hatası: $e');
      // Hata olsa bile devam et
    }
  }

  /// Odalara örnek mesajlar ekler
  static Future<void> _createSampleMessages(List<String> roomIds, List<String> userIds) async {
    try {
      final sampleMessages = [
        'Merhaba! 👋',
        'Bugün kimler var? 😊',
        'Harika bir grup! 🎉',
        'Ben de katılabilir miyim?',
        'Süper! 🚀',
        'Ne zaman başlıyoruz?',
        'Heyecanlıyım! 😄',
        'Herkese selam! 👋',
        'Bende varım! ✋',
        'Harika bir fikir!',
        'Çok güzel olacak 🌟',
        'Kesinlikle katılıyorum!',
        'Ne güzel! 😊',
        'Yardıma ihtiyacınız var mı?',
        'Ben de merak ediyorum',
        'Detayları paylaşır mısınız?',
        'Yer ayırttım bile! 📍',
        'Bence süper olur!',
        'Sayımı dahil edin! ✓',
        'Çok iyi! 👍',
      ];
      
      int totalMessages = 0;
      
      for (var i = 0; i < roomIds.length; i++) {
        final roomId = roomIds[i];
        
        // Her odaya 3-8 mesaj
        final messageCount = _random.nextInt(6) + 3;
        
        // Bu odanın üyelerini al (gerçek room data'dan değil, rastgele seç)
        final shuffledUsers = List<String>.from(userIds)..shuffle();
        final roomMembers = shuffledUsers.take(5).toList(); // İlk 5 kullanıcı
        
        for (var j = 0; j < messageCount; j++) {
          final senderId = roomMembers[_random.nextInt(roomMembers.length)];
          final message = sampleMessages[_random.nextInt(sampleMessages.length)];
          
          // Mesaj zamanı: Son 1-7 gün içinde
          final daysAgo = _random.nextInt(7) + 1;
          final timestamp = DateTime.now().subtract(Duration(days: daysAgo, hours: _random.nextInt(24)));
          
          await _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('messages')
              .add({
            'text': message,
            'senderId': senderId,
            'timestamp': Timestamp.fromDate(timestamp),
            'type': 'text',
          });
          
          totalMessages++;
        }
      }
      
      print('✓ $totalMessages mesaj oluşturuldu');
    } catch (e) {
      print('❌ Mesaj oluşturma hatası: $e');
      // Hata olsa bile devam et
    }
  }

  // ============================================
  // TEMİZLEME FONKSİYONLARI
  // ============================================

  /// Tüm test kullanıcılarını siler (user_ ile başlayanlar)
  static Future<void> deleteAllTestUsers() async {
    try {
      // user_ ile başlayan tüm kullanıcıları bul
      final users = await _firestore.collection('users').get();
      
      final testUsers = users.docs.where((doc) {
        final email = doc.data()['email'] as String?;
        return email != null && email.endsWith('@test.com');
      }).toList();
      
      if (testUsers.isEmpty) {
        print('ℹ️ Silinecek test kullanıcısı yok');
        return;
      }
      
      // Batch olarak sil
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;
      
      for (var doc in testUsers) {
        currentBatch.delete(doc.reference);
        operationCount++;
        
        // Firestore batch limiti 500
        if (operationCount >= 500) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
      }
      
      if (operationCount > 0) {
        batches.add(currentBatch);
      }
      
      // Tüm batch'leri commit et
      for (var batch in batches) {
        await batch.commit();
      }
      
      print('🗑️ ${testUsers.length} test kullanıcısı silindi');
    } catch (e) {
      print('❌ Kullanıcı silme hatası: $e');
    }
  }

  /// Tüm odaları siler
  static Future<void> deleteAllRooms() async {
    try {
      final rooms = await _firestore.collection('rooms').get();
      
      if (rooms.docs.isEmpty) {
        print('ℹ️ Silinecek oda yok');
        return;
      }
      
      int messageCount = 0;
      
      // Her odanın mesajlarını sil
      for (var room in rooms.docs) {
        final messages = await _firestore
            .collection('rooms')
            .doc(room.id)
            .collection('messages')
            .get();
        
        messageCount += messages.docs.length;
        
        // Mesajları batch ile sil
        if (messages.docs.isNotEmpty) {
          final batches = <WriteBatch>[];
          var currentBatch = _firestore.batch();
          var operationCount = 0;
          
          for (var message in messages.docs) {
            currentBatch.delete(message.reference);
            operationCount++;
            
            if (operationCount >= 500) {
              batches.add(currentBatch);
              currentBatch = _firestore.batch();
              operationCount = 0;
            }
          }
          
          if (operationCount > 0) {
            batches.add(currentBatch);
          }
          
          for (var batch in batches) {
            await batch.commit();
          }
        }
      }
      
      // Odaları sil
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;
      
      for (var doc in rooms.docs) {
        currentBatch.delete(doc.reference);
        operationCount++;
        
        if (operationCount >= 500) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
      }
      
      if (operationCount > 0) {
        batches.add(currentBatch);
      }
      
      for (var batch in batches) {
        await batch.commit();
      }
      
      print('🗑️ ${rooms.docs.length} oda ve $messageCount mesaj silindi');
    } catch (e) {
      print('❌ Oda silme hatası: $e');
    }
  }

  /// HER ŞEYİ SİL
  static Future<void> deleteEverything() async {
    print('🗑️ Tüm dummy data siliniyor...');
    await deleteAllRooms();
    await Future.delayed(const Duration(seconds: 1));
    await deleteAllTestUsers();
    print('✅ Temizlik tamamlandı!');
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