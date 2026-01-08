import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'room_list_page.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  bool _isTyping = false;
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _userPreferences = {};
  final Map<String, int> _scores = {};
  final Random _random = Random();
  
  List<Map<String, dynamic>> _recommendedRooms = [];
  bool _isLoadingRooms = false;
  
  // Loading durumları için
  final Map<String, bool> _joiningRooms = {};

  // ==================== GENİŞLETİLMİŞ KATEGORİLER ====================
  
  final Map<String, CategoryInfo> _categories = {
    // Spor & Fitness
    'sports': CategoryInfo(
      name: 'Spor',
      icon: Icons.sports_soccer,
      color: Colors.green,
      emoji: '⚽',
      description: 'Futbol, basketbol, voleybol...',
      tags: ['physical', 'energetic', 'team'],
    ),
    'fitness': CategoryInfo(
      name: 'Fitness',
      icon: Icons.fitness_center,
      color: Colors.orange,
      emoji: '💪',
      description: 'Egzersiz, spor salonu, antrenman',
      tags: ['physical', 'health', 'energetic'],
    ),
    'yoga': CategoryInfo(
      name: 'Yoga & Meditasyon',
      icon: Icons.self_improvement,
      color: Colors.teal,
      emoji: '🧘',
      description: 'Yoga, meditasyon, nefes egzersizi',
      tags: ['calm', 'health', 'mindful'],
    ),
    
    // Oyun & Eğlence
    'gaming': CategoryInfo(
      name: 'Video Oyunları',
      icon: Icons.gamepad,
      color: Colors.blue,
      emoji: '🎮',
      description: 'PC, konsol, mobil oyunlar',
      tags: ['entertainment', 'competitive', 'social'],
    ),
    'board_games': CategoryInfo(
      name: 'Masa Oyunları',
      icon: Icons.casino,
      color: Colors.brown,
      emoji: '🎲',
      description: 'Satranç, tavla, kutu oyunları',
      tags: ['mental', 'social', 'strategic'],
    ),
    'esports': CategoryInfo(
      name: 'E-Spor',
      icon: Icons.emoji_events,
      color: Colors.red,
      emoji: '🏆',
      description: 'Turnuvalar, rekabetçi oyunlar',
      tags: ['competitive', 'entertainment', 'team'],
    ),
    
    // Müzik & Sanat
    'music': CategoryInfo(
      name: 'Müzik',
      icon: Icons.music_note,
      color: Colors.purple,
      emoji: '🎵',
      description: 'Dinleme, çalma, söyleme',
      tags: ['creative', 'relaxing', 'social'],
    ),
    'art': CategoryInfo(
      name: 'Sanat',
      icon: Icons.palette,
      color: Colors.pink,
      emoji: '🎨',
      description: 'Resim, çizim, el sanatları',
      tags: ['creative', 'calm', 'expressive'],
    ),
    'photography': CategoryInfo(
      name: 'Fotoğrafçılık',
      icon: Icons.camera_alt,
      color: Colors.blueGrey,
      emoji: '📷',
      description: 'Fotoğraf çekimi, düzenleme',
      tags: ['creative', 'outdoor', 'visual'],
    ),
    'dance': CategoryInfo(
      name: 'Dans',
      icon: Icons.nightlife,
      color: Colors.deepPurple,
      emoji: '💃',
      description: 'Dans etme, öğrenme',
      tags: ['physical', 'creative', 'social'],
    ),
    
    // Eğitim & Gelişim
    'study': CategoryInfo(
      name: 'Ders Çalışma',
      icon: Icons.school,
      color: Colors.indigo,
      emoji: '📚',
      description: 'Sınav hazırlık, ödev',
      tags: ['mental', 'focused', 'educational'],
    ),
    'language': CategoryInfo(
      name: 'Dil Öğrenme',
      icon: Icons.translate,
      color: Colors.cyan,
      emoji: '🌍',
      description: 'İngilizce, Almanca, Japonca...',
      tags: ['educational', 'mental', 'social'],
    ),
    'coding': CategoryInfo(
      name: 'Kodlama',
      icon: Icons.code,
      color: Colors.green,
      emoji: '💻',
      description: 'Programlama, yazılım geliştirme',
      tags: ['mental', 'technical', 'focused'],
    ),
    'reading': CategoryInfo(
      name: 'Kitap Kulübü',
      icon: Icons.menu_book,
      color: Colors.brown,
      emoji: '📖',
      description: 'Kitap okuma, tartışma',
      tags: ['mental', 'calm', 'cultural'],
    ),
    
    // Sosyal & Sohbet
    'chat': CategoryInfo(
      name: 'Sohbet',
      icon: Icons.chat_bubble,
      color: Colors.teal,
      emoji: '💬',
      description: 'Genel sohbet, tanışma',
      tags: ['social', 'relaxing', 'friendly'],
    ),
    'debate': CategoryInfo(
      name: 'Tartışma',
      icon: Icons.forum,
      color: Colors.deepOrange,
      emoji: '🗣️',
      description: 'Fikir alışverişi, münazara',
      tags: ['mental', 'social', 'intellectual'],
    ),
    'networking': CategoryInfo(
      name: 'Networking',
      icon: Icons.people,
      color: Colors.blue,
      emoji: '🤝',
      description: 'Profesyonel bağlantılar',
      tags: ['professional', 'social', 'career'],
    ),
    
    // Film & Medya
    'movie': CategoryInfo(
      name: 'Film & Dizi',
      icon: Icons.movie,
      color: Colors.red,
      emoji: '🎬',
      description: 'İzleme partisi, tartışma',
      tags: ['entertainment', 'social', 'relaxing'],
    ),
    'anime': CategoryInfo(
      name: 'Anime & Manga',
      icon: Icons.auto_awesome,
      color: Colors.pink,
      emoji: '🌸',
      description: 'Anime izleme, manga okuma',
      tags: ['entertainment', 'cultural', 'social'],
    ),
    'podcast': CategoryInfo(
      name: 'Podcast',
      icon: Icons.podcasts,
      color: Colors.purple,
      emoji: '🎙️',
      description: 'Podcast dinleme, kayıt',
      tags: ['educational', 'entertainment', 'creative'],
    ),
    
    // Yemek & Yaşam
    'food': CategoryInfo(
      name: 'Yemek',
      icon: Icons.restaurant,
      color: Colors.amber,
      emoji: '🍕',
      description: 'Yemek yapma, tarifler',
      tags: ['creative', 'social', 'lifestyle'],
    ),
    'cooking': CategoryInfo(
      name: 'Yemek Yapma',
      icon: Icons.soup_kitchen,
      color: Colors.orange,
      emoji: '👨‍🍳',
      description: 'Birlikte yemek yapma',
      tags: ['creative', 'social', 'learning'],
    ),
    'coffee': CategoryInfo(
      name: 'Kahve & Çay',
      icon: Icons.coffee,
      color: Colors.brown,
      emoji: '☕',
      description: 'Kahve sohbetleri',
      tags: ['social', 'relaxing', 'casual'],
    ),
    
    // Seyahat & Outdoor
    'travel': CategoryInfo(
      name: 'Seyahat',
      icon: Icons.flight,
      color: Colors.lightBlue,
      emoji: '✈️',
      description: 'Gezi planları, deneyimler',
      tags: ['adventure', 'social', 'cultural'],
    ),
    'outdoor': CategoryInfo(
      name: 'Outdoor',
      icon: Icons.terrain,
      color: Colors.green,
      emoji: '🏕️',
      description: 'Doğa, kamp, yürüyüş',
      tags: ['physical', 'adventure', 'nature'],
    ),
    
    // Teknoloji
    'tech': CategoryInfo(
      name: 'Teknoloji',
      icon: Icons.computer,
      color: Colors.blueGrey,
      emoji: '🖥️',
      description: 'Teknoloji haberleri, incelemeler',
      tags: ['technical', 'educational', 'modern'],
    ),
    'crypto': CategoryInfo(
      name: 'Kripto & Finans',
      icon: Icons.currency_bitcoin,
      color: Colors.amber,
      emoji: '💰',
      description: 'Kripto, yatırım, finans',
      tags: ['technical', 'professional', 'modern'],
    ),
    
    // Diğer
    'pets': CategoryInfo(
      name: 'Evcil Hayvanlar',
      icon: Icons.pets,
      color: Colors.orange,
      emoji: '🐾',
      description: 'Kedi, köpek, hayvan sevgisi',
      tags: ['lifestyle', 'social', 'relaxing'],
    ),
    'cars': CategoryInfo(
      name: 'Otomobil',
      icon: Icons.directions_car,
      color: Colors.red,
      emoji: '🚗',
      description: 'Arabalar, motorsporları',
      tags: ['hobby', 'technical', 'social'],
    ),
    'fashion': CategoryInfo(
      name: 'Moda & Stil',
      icon: Icons.checkroom,
      color: Colors.pink,
      emoji: '👗',
      description: 'Moda, giyim, stil',
      tags: ['creative', 'lifestyle', 'social'],
    ),
  };

  // ==================== SORU SİSTEMİ ====================

  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'mood',
      'type': 'options',
      'options': [
        {
          'text': '⚡ Enerjik ve Aktif',
          'value': 'energetic',
          'categories': ['sports', 'fitness', 'dance', 'esports', 'outdoor'],
          'score': {'physical': 4, 'energetic': 3}
        },
        {
          'text': '🧘 Sakin ve Huzurlu',
          'value': 'calm',
          'categories': ['yoga', 'reading', 'art', 'coffee', 'podcast'],
          'score': {'calm': 4, 'relaxing': 3}
        },
        {
          'text': '🎉 Sosyal ve Eğlenceli',
          'value': 'social',
          'categories': ['chat', 'food', 'movie', 'gaming', 'music'],
          'score': {'social': 4, 'entertainment': 3}
        },
        {
          'text': '🎯 Odaklanmış ve Üretken',
          'value': 'focused',
          'categories': ['study', 'coding', 'language', 'tech'],
          'score': {'mental': 4, 'focused': 3}
        },
        {
          'text': '🎨 Yaratıcı ve İlham Dolu',
          'value': 'creative',
          'categories': ['art', 'music', 'photography', 'cooking', 'fashion'],
          'score': {'creative': 4, 'expressive': 3}
        },
        {
          'text': '🌟 Maceraperest',
          'value': 'adventurous',
          'categories': ['travel', 'outdoor', 'esports', 'debate'],
          'score': {'adventure': 4, 'exciting': 3}
        },
      ],
    },
    {
      'id': 'time',
      'type': 'options',
      'options': [
        {'text': '⏰ 30 dakikadan az', 'value': 'very_short', 'maxDuration': 30},
        {'text': '🕐 30 dk - 1 saat', 'value': 'short', 'maxDuration': 60},
        {'text': '🕑 1-2 saat', 'value': 'medium', 'maxDuration': 120},
        {'text': '🕔 2-4 saat', 'value': 'long', 'maxDuration': 240},
        {'text': '🌟 Zaman sınırım yok', 'value': 'unlimited', 'maxDuration': 999},
      ],
    },
    {
      'id': 'group',
      'type': 'options',
      'options': [
        {'text': '👤 Tek başıma rahatım', 'value': 'solo', 'minPeople': 1, 'maxPeople': 3},
        {'text': '👫 Küçük grup (2-4 kişi)', 'value': 'small', 'minPeople': 2, 'maxPeople': 5},
        {'text': '👥 Orta grup (5-10 kişi)', 'value': 'medium', 'minPeople': 4, 'maxPeople': 12},
        {'text': '🎊 Büyük grup (10+ kişi)', 'value': 'large', 'minPeople': 8, 'maxPeople': 50},
        {'text': '🎲 Fark etmez', 'value': 'any', 'minPeople': 1, 'maxPeople': 100},
      ],
    },
    {
      'id': 'category',
      'type': 'category_select',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _startConversation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage(_getWelcomeMessage());
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        _askNextQuestion();
      });
    });
  }

  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour >= 5 && hour < 12) {
      greeting = 'Günaydın';
      emoji = '☀️';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'İyi günler';
      emoji = '👋';
    } else if (hour >= 18 && hour < 22) {
      greeting = 'İyi akşamlar';
      emoji = '🌆';
    } else {
      greeting = 'İyi geceler';
      emoji = '🌙';
    }
    
    final messages = [
      '$greeting! $emoji\n\nBen senin AI asistanınım. Sana en uygun etkinlik odalarını bulmak için birkaç soru soracağım.',
      '$greeting! $emoji\n\nHadi sana mükemmel aktiviteler bulalım! Birkaç kısa soruyla tercihlerini öğreneceğim.',
      '$greeting! $emoji\n\nBugün nasıl vakit geçirmek istediğini merak ediyorum. Hazırsan başlayalım!',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  void _askNextQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _makeSmartRecommendation();
      return;
    }

    final question = _questions[_currentQuestionIndex];
    
    if (question['type'] == 'category_select') {
      _askCategoryQuestion();
    } else {
      String questionText = _getQuestionText(question['id']);
      _addBotMessage(questionText);
      _addQuickReplies(question['options']);
    }
  }

  String _getQuestionText(String questionId) {
    final texts = {
      'mood': [
        '🤔 Öncelikle, şu an nasıl hissediyorsun?',
        '💭 Bugünkü ruh halini nasıl tanımlarsın?',
        '✨ Şu anki enerjin nasıl?',
      ],
      'time': [
        '⏰ Bu aktivite için ne kadar vaktin var?',
        '🕐 Elinde ne kadar zaman var?',
        '⌚ Ne kadar süre ayırabilirsin?',
      ],
      'group': [
        '👥 Kaç kişiyle birlikte olmak istersin?',
        '🎯 Grup büyüklüğü tercihin nedir?',
        '👫 Yalnız mı yoksa kalabalık mı?',
      ],
    };
    
    final options = texts[questionId] ?? ['Bir sonraki soru:'];
    return options[_random.nextInt(options.length)];
  }

  void _askCategoryQuestion() {
    _addBotMessage('🎯 Son olarak, hangi tür aktiviteler ilgini çekiyor?\n\nBirden fazla seçebilirsin:');
    _addCategorySelector();
  }

  void _handleQuickReply(Map<String, dynamic> option) {
    final questionId = _questions[_currentQuestionIndex]['id'];
    
    _userPreferences[questionId] = option;
    
    if (option['score'] != null) {
      (option['score'] as Map<String, dynamic>).forEach((key, value) {
        _scores[key] = (_scores[key] ?? 0) + (value as int);
      });
    }
    
    _addUserMessage(option['text']);
    
    setState(() {
      _messages.removeWhere((msg) => msg.isQuickReply || msg.isCategorySelector);
    });
    
    setState(() => _isTyping = true);
    Future.delayed(Duration(milliseconds: 300 + _random.nextInt(300)), () {
      _addBotMessage(_getTransitionMessage());
      _currentQuestionIndex++;
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _askNextQuestion();
      });
    });
  }

  void _handleCategorySelection(List<String> selectedCategories) {
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir kategori seç!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _userPreferences['categories'] = selectedCategories;
    
    // Seçilen kategorileri göster
    final categoryNames = selectedCategories
        .map((c) => _categories[c]?.emoji ?? '')
        .join(' ');
    
    _addUserMessage('Seçimlerim: $categoryNames');
    
    setState(() {
      _messages.removeWhere((msg) => msg.isCategorySelector);
    });
    
    setState(() => _isTyping = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage('Mükemmel seçimler! 🎉');
      _currentQuestionIndex++;
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeSmartRecommendation();
      });
    });
  }

  String _getTransitionMessage() {
    final messages = ['Anladım! 👍', 'Süper! ⭐', 'Harika! ✨', 'Mükemmel! 🎯', 'Çok iyi! 💫', 'Tamam! 📝'];
    return messages[_random.nextInt(messages.length)];
  }

  // ==================== AKILLI ÖNERİ SİSTEMİ ====================
  
  Future<void> _makeSmartRecommendation() async {
    setState(() {
      _isTyping = true;
      _isLoadingRooms = true;
    });
    
    _addBotMessage('🔍 Senin için en uygun odaları arıyorum...');
    
    try {
      final rooms = await _fetchAndScoreRooms();
      
      setState(() {
        _recommendedRooms = rooms;
        _isLoadingRooms = false;
        _isTyping = false;
      });
      
      if (rooms.isEmpty) {
        _addBotMessage(_getNoRoomsMessage());
        _addCreateRoomSuggestion();
      } else {
        _addBotMessage(_getRecommendationMessage(rooms.length));
        _addRoomCards(rooms);
      }
      
      _addActionButtons();
      
    } catch (e) {
      print('Oda arama hatası: $e');
      setState(() {
        _isLoadingRooms = false;
        _isTyping = false;
      });
      _addBotMessage('😅 Bir sorun oluştu ama tüm odalara göz atabilirsin!');
      _addActionButtons();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndScoreRooms() async {
    final selectedCategories = _userPreferences['categories'] as List<String>? ?? [];
    final moodPref = _userPreferences['mood'] as Map<String, dynamic>?;
    final groupPref = _userPreferences['group'] as Map<String, dynamic>?;
    
    // Mood'dan gelen kategorileri de ekle
    List<String> allCategories = [...selectedCategories];
    if (moodPref != null && moodPref['categories'] != null) {
      allCategories.addAll(List<String>.from(moodPref['categories']));
    }
    allCategories = allCategories.toSet().toList(); // Tekrarları kaldır
    
    List<QueryDocumentSnapshot> allDocs = [];
    
    if (allCategories.isNotEmpty) {
      // Seçilen kategorilerdeki odaları çek
      // Firestore 'whereIn' max 10 değer alır
      final categoriesToQuery = allCategories.take(10).toList();
      
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('isActive', isEqualTo: true)
          .where('category', whereIn: categoriesToQuery)
          .limit(30)
          .get();
      
      allDocs = snapshot.docs;
    }
    
    // Eğer az sonuç varsa, tüm aktif odaları da çek
    if (allDocs.length < 5) {
      final allRoomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('isActive', isEqualTo: true)
          .limit(30)
          .get();
      
      // Tekrar eden odaları ekleme
      final existingIds = allDocs.map((d) => d.id).toSet();
      for (var doc in allRoomsSnapshot.docs) {
        if (!existingIds.contains(doc.id)) {
          allDocs.add(doc);
        }
      }
    }
    
    return _scoreAndSortRooms(allDocs, allCategories, groupPref);
  }

  List<Map<String, dynamic>> _scoreAndSortRooms(
    List<QueryDocumentSnapshot> docs,
    List<String> preferredCategories,
    Map<String, dynamic>? groupPref,
  ) {
    final List<Map<String, dynamic>> scoredRooms = [];
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final roomId = doc.id;
      
      final participants = List<String>.from(data['participants'] ?? []);
      final maxParticipants = data['maxParticipants'] ?? 20;
      final category = data['category'] as String? ?? 'chat';
      
      // Zaten katıldığımız veya dolu odaları atla
      if (participants.contains(_currentUserId)) continue;
      if (participants.length >= maxParticipants) continue;
      
      double score = 10.0;
      
      // Kategori uyumu (+15 puan)
      if (preferredCategories.contains(category)) {
        score += 15;
      }
      
      // Grup büyüklüğü uyumu (+10 puan)
      if (groupPref != null) {
        final minPeople = groupPref['minPeople'] ?? 1;
        final maxPeople = groupPref['maxPeople'] ?? 100;
        
        if (maxParticipants >= minPeople && maxParticipants <= maxPeople + 5) {
          score += 10;
        }
        
        // Mevcut katılımcı sayısı tercih aralığında mı?
        if (participants.length >= minPeople - 1 && participants.length <= maxPeople) {
          score += 5;
        }
      }
      
      // Aktif oda bonusu (en az 1 kişi varsa)
      if (participants.isNotEmpty) {
        score += 5 + (participants.length * 0.5);
      }
      
      // Yeni oda bonusu (doluluk oranı düşükse)
      final fillRate = participants.length / maxParticipants;
      if (fillRate < 0.5) {
        score += 3;
      }
      
      // Rastgele varyasyon
      score += _random.nextDouble() * 5;
      
      scoredRooms.add({
        'id': roomId,
        'score': score,
        'matchReason': _getMatchReason(category, preferredCategories, participants.length),
        ...data,
      });
    }
    
    scoredRooms.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return scoredRooms.take(6).toList();
  }

  String _getMatchReason(String category, List<String> preferred, int participantCount) {
    if (preferred.contains(category)) {
      return '✓ Tercihlerine uygun';
    } else if (participantCount > 3) {
      return '🔥 Popüler oda';
    } else if (participantCount == 0) {
      return '🆕 Yeni açıldı';
    }
    return '💡 Öneri';
  }

  String _getNoRoomsMessage() {
    return '🤔 Şu an kriterlerine tam uygun aktif oda bulamadım.\n\nAma endişelenme! Yeni odalar sürekli açılıyor veya sen bir tane oluşturabilirsin!';
  }

  String _getRecommendationMessage(int count) {
    final moodPref = _userPreferences['mood'] as Map<String, dynamic>?;
    
    String intro = '🎉 Harika! Senin için $count oda buldum!\n\n';
    
    if (moodPref != null) {
      switch (moodPref['value']) {
        case 'energetic':
          intro += '⚡ Enerjini değerlendirebileceğin aktiviteler:';
          break;
        case 'calm':
          intro += '🧘 Rahatlamana yardımcı olacak odalar:';
          break;
        case 'social':
          intro += '🎉 Sosyalleşmek için harika ortamlar:';
          break;
        case 'focused':
          intro += '🎯 Odaklanmana uygun yerler:';
          break;
        case 'creative':
          intro += '🎨 Yaratıcılığını ortaya çıkaracak odalar:';
          break;
        case 'adventurous':
          intro += '🌟 Macera dolu aktiviteler:';
          break;
        default:
          intro += 'İşte sana uygun odalar:';
      }
    }
    
    return intro;
  }

  // ==================== UI BUILDER METHODS ====================

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addQuickReplies(List<Map<String, dynamic>> options) {
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        timestamp: DateTime.now(),
        isQuickReply: true,
        quickReplies: options,
      ));
    });
    _scrollToBottom();
  }

  void _addCategorySelector() {
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        timestamp: DateTime.now(),
        isCategorySelector: true,
      ));
    });
    _scrollToBottom();
  }

  void _addRoomCards(List<Map<String, dynamic>> rooms) {
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        timestamp: DateTime.now(),
        isRoomList: true,
        rooms: rooms,
      ));
    });
    _scrollToBottom();
  }

  void _addCreateRoomSuggestion() {
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        timestamp: DateTime.now(),
        isCreateRoomCard: true,
      ));
    });
    _scrollToBottom();
  }

  void _addActionButtons() {
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        timestamp: DateTime.now(),
        isActionButton: true,
      ));
    });
    _scrollToBottom();
  }

  void _handleActionButton(String action) {
    switch (action) {
      case 'browse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RoomListPage()),
        );
        break;
      case 'restart':
        _resetConversation();
        break;
      case 'home':
        Navigator.pop(context);
        break;
    }
  }

  Future<void> _joinRoom(Map<String, dynamic> room) async {
    final roomId = room['id'] as String;
    
    if (_joiningRooms[roomId] == true) return;
    
    setState(() {
      _joiningRooms[roomId] = true;
    });
    
    try {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
      
      // Önce odanın güncel durumunu kontrol et
      final roomDoc = await roomRef.get();
      if (!roomDoc.exists) {
        throw Exception('Oda bulunamadı');
      }
      
      final roomData = roomDoc.data()!;
      final participants = List<String>.from(roomData['participants'] ?? []);
      final maxParticipants = roomData['maxParticipants'] ?? 20;
      
      if (participants.contains(_currentUserId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zaten bu odadasın! 😊'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (participants.length >= maxParticipants) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oda dolu! 😔'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Odaya katıl
      await roomRef.update({
        'participants': FieldValue.arrayUnion([_currentUserId]),
        'participantCount': FieldValue.increment(1),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${room['name']} odasına katıldın! 🎉',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Kısa bir gecikme ile odalar sayfasına git
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RoomListPage()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _joiningRooms[roomId] = false;
        });
      }
    }
  }

  void _resetConversation() {
    setState(() {
      _messages.clear();
      _currentQuestionIndex = 0;
      _userPreferences.clear();
      _scores.clear();
      _recommendedRooms.clear();
      _joiningRooms.clear();
    });
    _startConversation();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageItem(_messages[index]);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade500, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Asistan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Sana özel etkinlik önerileri',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: _resetConversation,
            tooltip: 'Yeniden Başlat',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, color: Colors.grey.shade500, size: 18),
              const SizedBox(width: 10),
              Text(
                'Seçeneklere tıklayarak cevap ver',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.isQuickReply) {
      return _buildQuickReplies(message.quickReplies!);
    }
    if (message.isCategorySelector) {
      return _buildCategorySelector();
    }
    if (message.isRoomList) {
      return _buildRoomList(message.rooms!);
    }
    if (message.isCreateRoomCard) {
      return _buildCreateRoomCard();
    }
    if (message.isActionButton) {
      return _buildActionButtons();
    }
    return _buildMessage(message);
  }

  Widget _buildMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isUser) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isUser 
                      ? Colors.blue.shade500 
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: message.isUser 
                        ? const Radius.circular(20) 
                        : const Radius.circular(6),
                    bottomRight: message.isUser 
                        ? const Radius.circular(6) 
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text ?? '',
                  style: TextStyle(
                    color: message.isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, size: 16, color: Colors.blue.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(List<Map<String, dynamic>> options) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: options.map((option) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleQuickReply(option),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  option['text'],
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return _CategorySelectorWidget(
      categories: _categories,
      onConfirm: _handleCategorySelection,
    );
  }

  Widget _buildRoomList(List<Map<String, dynamic>> rooms) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: rooms.map((room) => _buildRoomCard(room)).toList(),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final category = room['category'] as String? ?? 'chat';
    final catInfo = _categories[category] ?? _categories['chat']!;
    final participants = List<String>.from(room['participants'] ?? []);
    final maxParticipants = room['maxParticipants'] ?? 20;
    final participantCount = participants.length;
    final isFull = participantCount >= maxParticipants;
    final isJoined = participants.contains(_currentUserId);
    final isJoining = _joiningRooms[room['id']] == true;
    final matchReason = room['matchReason'] as String? ?? '';
    
    // Doluluk yüzdesi
    final fillPercent = (participantCount / maxParticipants * 100).round();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isJoined 
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: (isJoined || isFull || isJoining) ? null : () => _joinRoom(room),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım: Kategori + Match Reason
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: catInfo.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(catInfo.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            catInfo.name,
                            style: TextStyle(
                              color: catInfo.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (matchReason.isNotEmpty)
                      Text(
                        matchReason,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    const Spacer(),
                    // Katılımcı sayısı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull 
                            ? Colors.red.shade50 
                            : fillPercent > 70 
                                ? Colors.orange.shade50 
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: isFull 
                                ? Colors.red 
                                : fillPercent > 70 
                                    ? Colors.orange 
                                    : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$participantCount/$maxParticipants',
                            style: TextStyle(
                              color: isFull 
                                  ? Colors.red 
                                  : fillPercent > 70 
                                      ? Colors.orange 
                                      : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Oda adı ve açıklama
                Row(
                  children: [
                    // Kategori ikonu (büyük)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: catInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        catInfo.icon,
                        color: catInfo.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // İsim ve açıklama
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room['name'] ?? 'İsimsiz Oda',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (room['description'] != null && 
                              room['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              room['description'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // Katıl butonu
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (isJoined || isFull || isJoining) 
                        ? null 
                        : () => _joinRoom(room),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined
                          ? Colors.green
                          : isFull
                              ? Colors.grey.shade400
                              : catInfo.color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isJoined 
                          ? Colors.green 
                          : Colors.grey.shade300,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isJoined 
                                    ? Icons.check_circle 
                                    : isFull 
                                        ? Icons.block 
                                        : Icons.login,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isJoined 
                                    ? 'Katıldın ✓' 
                                    : isFull 
                                        ? 'Oda Dolu' 
                                        : 'Odaya Katıl',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRoomCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.add_circle_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Kendi Odanı Oluştur!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'İstediğin aktiviteyi başlat ve insanları davet et',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oda oluşturma özelliği yakında! 🚀'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Oda Oluştur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionButton(
            icon: Icons.explore,
            text: 'Tüm Odaları Keşfet',
            color: Colors.blue,
            onTap: () => _handleActionButton('browse'),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.refresh,
            text: 'Farklı Tercihlerle Dene',
            color: Colors.orange,
            onTap: () => _handleActionButton('restart'),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.home,
            text: 'Ana Sayfaya Dön',
            color: Colors.grey,
            onTap: () => _handleActionButton('home'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                _buildTypingDot(1),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: EdgeInsets.only(left: index > 0 ? 5 : 0),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ==================== KATEGORİ SEÇİCİ WIDGET ====================

class _CategorySelectorWidget extends StatefulWidget {
  final Map<String, CategoryInfo> categories;
  final Function(List<String>) onConfirm;

  const _CategorySelectorWidget({
    required this.categories,
    required this.onConfirm,
  });

  @override
  State<_CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<_CategorySelectorWidget> {
  final Set<String> _selected = {};

  // Kategorileri gruplara ayır
  final Map<String, List<String>> _groups = {
    'Spor & Fitness': ['sports', 'fitness', 'yoga', 'dance', 'outdoor'],
    'Oyun & Eğlence': ['gaming', 'board_games', 'esports'],
    'Müzik & Sanat': ['music', 'art', 'photography'],
    'Eğitim & Gelişim': ['study', 'language', 'coding', 'reading'],
    'Sosyal': ['chat', 'debate', 'networking', 'coffee'],
    'Film & Medya': ['movie', 'anime', 'podcast'],
    'Yemek': ['food', 'cooking'],
    'Diğer': ['travel', 'tech', 'crypto', 'pets', 'cars', 'fashion'],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seçim sayısı göstergesi
          Row(
            children: [
              Icon(Icons.category, color: Colors.purple.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_selected.length} kategori seçildi',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('Temizle', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Kategori grupları
          ..._groups.entries.map((group) {
            final validCategories = group.value
                .where((c) => widget.categories.containsKey(c))
                .toList();
            
            if (validCategories.isEmpty) return const SizedBox();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    group.key,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: validCategories.map((catId) {
                    final cat = widget.categories[catId]!;
                    final isSelected = _selected.contains(catId);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(catId);
                          } else {
                            _selected.add(catId);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? cat.color.withOpacity(0.15) 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: isSelected ? cat.color : Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.check, size: 14, color: cat.color),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Onayla butonu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selected.isEmpty 
                  ? null 
                  : () => widget.onConfirm(_selected.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _selected.isEmpty 
                    ? 'En az 1 kategori seç' 
                    : 'Seçimleri Onayla (${_selected.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MODELS ====================

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;
  final String description;
  final List<String> tags;

  const CategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.emoji,
    required this.description,
    required this.tags,
  });
}

class ChatMessage {
  final String? text;
  final bool isUser;
  final DateTime timestamp;
  final bool isQuickReply;
  final List<Map<String, dynamic>>? quickReplies;
  final bool isCategorySelector;
  final bool isActionButton;
  final bool isRoomList;
  final List<Map<String, dynamic>>? rooms;
  final bool isCreateRoomCard;

  ChatMessage({
    this.text,
    required this.isUser,
    required this.timestamp,
    this.isQuickReply = false,
    this.quickReplies,
    this.isCategorySelector = false,
    this.isActionButton = false,
    this.isRoomList = false,
    this.rooms,
    this.isCreateRoomCard = false,
  });
}