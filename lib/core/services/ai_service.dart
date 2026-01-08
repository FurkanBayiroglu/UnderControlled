import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI Service - Backend ile iletişim (Dil Destekli)
class AiService {
  // Singleton
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // ⚠️ BURAYA KENDI API URL'İNİ YAZ
  static const String _baseUrl = 'https://gcxhw9kk22.execute-api.eu-central-1.amazonaws.com/dev';
  
  // Timeout süreleri
  static const Duration _healthTimeout = Duration(seconds: 3);
  static const Duration _chatTimeout = Duration(seconds: 15);
  static const Duration _startTimeout = Duration(seconds: 5);
  
  // Session
  String? _sessionId;
  String? _userId;
  String _language = 'tr'; // Default Türkçe
  
  // Health cache
  DateTime? _lastHealthCheck;
  bool? _lastHealthResult;

  // HTTP Client - reuse
  final http.Client _client = http.Client();

  /// Dili ayarla
  void setLanguage(String languageCode) {
    _language = languageCode;
  }

  /// Health check
  Future<bool> healthCheck() async {
    // 1 dakika cache
    if (_lastHealthCheck != null && 
        _lastHealthResult != null &&
        DateTime.now().difference(_lastHealthCheck!) < const Duration(minutes: 1)) {
      return _lastHealthResult!;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/health/ping'))
          .timeout(_healthTimeout);
      
      _lastHealthResult = response.statusCode == 200;
      _lastHealthCheck = DateTime.now();
      return _lastHealthResult!;
    } catch (e) {
      _lastHealthResult = false;
      return false;
    }
  }

  /// Sohbet başlat
  Future<ChatStartResponse> startChat({String? userName, String? language}) async {
    try {
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      if (language != null) _language = language;
      
      // Debug log
      print('🌍 AiService startChat - Language: $_language');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/chat/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'userName': userName,
          'language': _language, // Dil bilgisi gönder
        }),
      ).timeout(_startTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _sessionId = data['sessionId'] as String?;
        
        return ChatStartResponse(
          success: true,
          sessionId: _sessionId,
          message: data['message'] as String?,
          quickReplies: _parseQuickReplies(data['quickReplies']),
        );
      }
      
      return ChatStartResponse(success: false);
    } catch (e) {
      print('startChat error: $e');
      return ChatStartResponse(success: false, error: e.toString());
    }
  }

  /// Mesaj gönder
  Future<ChatResponse> sendMessage(
    String message, {
    Map<String, dynamic>? preferences,
    String? language,
  }) async {
    try {
      if (language != null) _language = language;
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'sessionId': _sessionId,
          'message': message,
          'language': _language, // Dil bilgisi gönder
          if (preferences != null) 'preferences': preferences,
        }),
      ).timeout(_chatTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        return ChatResponse(
          success: true,
          message: data['message'] as String?,
          quickReplies: _parseQuickReplies(data['quickReplies']),
          recommendations: _parseRecommendations(data['recommendations']),
          suggestedCategories: _parseStringList(data['suggestedCategories']),
          intent: data['intent'] as String?,
        );
      }
      
      return ChatResponse(success: false);
    } on TimeoutException {
      return ChatResponse(
        success: false,
        message: _language == 'tr' 
            ? 'Yanıt uzun sürdü, tekrar dener misin? ⏱️'
            : 'Response took too long, can you try again? ⏱️',
      );
    } catch (e) {
      print('sendMessage error: $e');
      return ChatResponse(success: false, error: e.toString());
    }
  }

  /// Oda önerileri al
  Future<List<RoomRecommendation>> getRecommendations({
    List<String>? categories,
    String? mood,
    int limit = 5,
    String? language,
  }) async {
    try {
      if (language != null) _language = language;
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'language': _language, // Dil bilgisi gönder
          'preferences': {
            if (categories != null) 'categories': categories,
            if (mood != null) 'mood': mood,
          },
          'limit': limit,
        }),
      ).timeout(_chatTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseRecommendations(data['recommendations']);
      }
      return [];
    } catch (e) {
      print('getRecommendations error: $e');
      return [];
    }
  }

  /// Öneri geçmişini sıfırla
  Future<void> resetRecommendationHistory() async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/api/recommend/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userId}),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Session sıfırla
  Future<void> resetSession() async {
    if (_sessionId != null) {
      try {
        await _client.delete(
          Uri.parse('$_baseUrl/api/chat/session/$_sessionId'),
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    _sessionId = null;
    await resetRecommendationHistory();
  }

  // ============ HELPERS ============

  List<QuickReply> _parseQuickReplies(dynamic data) {
    if (data == null || data is! List) return [];
    
    return data.map<QuickReply>((item) {
      final map = item as Map<String, dynamic>;
      return QuickReply(
        text: map['text'] as String? ?? '',
        value: map['value'] as String? ?? '',
        emoji: map['emoji'] as String?,
      );
    }).toList();
  }

  List<RoomRecommendation> _parseRecommendations(dynamic data) {
    if (data == null || data is! List) return [];
    
    return data.map<RoomRecommendation>((item) {
      final map = item as Map<String, dynamic>;
      return RoomRecommendation(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Unnamed Room',
        category: map['category'] as String? ?? 'chat',
        participantCount: map['participantCount'] as int? ?? 0,
        maxParticipants: map['maxParticipants'] as int? ?? 20,
        matchReason: map['matchReason'] as String? ?? '',
        aiExplanation: map['aiExplanation'] as String?,
        score: (map['score'] as num?)?.toDouble(),
      );
    }).toList();
  }

  List<String> _parseStringList(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map<String>((e) => e.toString()).toList();
  }

  void dispose() {
    _client.close();
  }
}

// ============ MODELS ============

class ChatStartResponse {
  final bool success;
  final String? sessionId;
  final String? message;
  final List<QuickReply> quickReplies;
  final String? error;

  const ChatStartResponse({
    required this.success,
    this.sessionId,
    this.message,
    this.quickReplies = const [],
    this.error,
  });
}

class ChatResponse {
  final bool success;
  final String? message;
  final List<QuickReply> quickReplies;
  final List<RoomRecommendation> recommendations;
  final List<String> suggestedCategories;
  final String? intent;
  final String? error;

  const ChatResponse({
    required this.success,
    this.message,
    this.quickReplies = const [],
    this.recommendations = const [],
    this.suggestedCategories = const [],
    this.intent,
    this.error,
  });
}

class QuickReply {
  final String text;
  final String value;
  final String? emoji;

  const QuickReply({
    required this.text,
    required this.value,
    this.emoji,
  });
}

class RoomRecommendation {
  final String id;
  final String name;
  final String category;
  final int participantCount;
  final int maxParticipants;
  final String matchReason;
  final String? aiExplanation;
  final double? score;

  const RoomRecommendation({
    required this.id,
    required this.name,
    required this.category,
    required this.participantCount,
    required this.maxParticipants,
    required this.matchReason,
    this.aiExplanation,
    this.score,
  });
}
