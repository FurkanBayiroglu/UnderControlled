import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../rooms/presentation/pages/room_detail_page.dart';

/// AI Asistan Sayfası - Localization Destekli (TR/EN)
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> 
    with SingleTickerProviderStateMixin {
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final AiService _aiService = AiService();
  
  final ValueNotifier<List<ChatBubble>> _messages = ValueNotifier([]);
  final ValueNotifier<List<QuickReply>> _quickReplies = ValueNotifier([]);
  final ValueNotifier<bool> _isTyping = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String? _sessionId;
  final Map<String, dynamic> _preferences = {};

  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);

  // Localization
  late _AiAssistantLocalizations _l10n;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // LocaleProvider'dan dil ayarını al (sistem locale'i değil, uygulama ayarı)
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _l10n = _AiAssistantLocalizations(localeProvider.currentLanguage);
    
    // İlk kez çağrıldığında chat'i başlat
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() => _initializeChat());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _messages.dispose();
    _quickReplies.dispose();
    _isTyping.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final isHealthy = await _aiService.healthCheck().timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );
    
    if (!mounted) return;
    
    if (!isHealthy) {
      _isLoading.value = false;
      _fadeController.forward();
      _addBotMessage(_l10n.connectionError);
      return;
    }

    final userName = FirebaseAuth.instance.currentUser?.displayName;
    
    // Debug: Hangi dil gönderiliyor?
    debugPrint('🌍 Language Code: ${_l10n.languageCode}');
    
    final response = await _aiService.startChat(
      userName: userName,
      language: _l10n.languageCode, // Dil bilgisi gönder
    ).timeout(
      const Duration(seconds: 3),
      onTimeout: () => ChatStartResponse(success: false),
    );

    if (!mounted) return;

    _sessionId = response.sessionId;
    _isLoading.value = false;
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    
    if (response.success && response.message != null) {
      _addBotMessage(response.message!);
      _quickReplies.value = response.quickReplies;
    } else {
      _addBotMessage(_l10n.defaultGreeting);
    }
  }

  void _addBotMessage(String text) {
    _messages.value = [..._messages.value, ChatBubble(text: text, isUser: false)];
    _isTyping.value = false;
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    _messages.value = [..._messages.value, ChatBubble(text: text, isUser: true)];
    _quickReplies.value = [];
    _scrollToBottom();
  }

  void _addRoomCards(List<RoomRecommendation> rooms) {
    _messages.value = [..._messages.value, ChatBubble(isUser: false, isRoomList: true, rooms: rooms)];
    _scrollToBottom();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addUserMessage(message);
    _inputController.clear();
    
    _isTyping.value = true;

    final response = await _aiService.sendMessage(
      message,
      preferences: _preferences.isNotEmpty ? _preferences : null,
      language: _l10n.languageCode, // Dil bilgisi gönder
    );

    if (!mounted) return;
    
    _isTyping.value = false;

    if (response.success) {
      _addBotMessage(response.message ?? _l10n.somethingWentWrong);
      _quickReplies.value = response.quickReplies;
      
      if (response.suggestedCategories.isNotEmpty) {
        _preferences['categories'] = response.suggestedCategories;
      }
      
      if (response.recommendations.isNotEmpty) {
        _addRoomCards(response.recommendations);
      }
    } else {
      _addBotMessage(_l10n.tryAgain);
    }
  }

  void _handleQuickReply(QuickReply reply) {
    if (['energetic', 'calm', 'social', 'focused'].contains(reply.value)) {
      _preferences['mood'] = reply.value;
    } else if (['gaming', 'music', 'sports', 'coding', 'movie', 'chat'].contains(reply.value)) {
      _preferences['categories'] = [reply.value];
    }
    _sendMessage(reply.text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _joinRoom(String roomId, String roomName) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showSnackBar(_l10n.pleaseSignIn, Colors.red);
        return;
      }

      _showSnackBar(_l10n.joiningRoom, Colors.blue);

      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'participantCount': FieldValue.increment(1),
      });

      if (!mounted) return;

      _showSnackBar(_l10n.joinedRoom(roomName), Colors.green);

      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;

      // Room Detail sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoomDetailPage(roomId: roomId),
        ),
      );

    } catch (e) {
      debugPrint('Join room error: $e');
      if (mounted) {
        _showSnackBar(_l10n.joinError, Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restartChat() async {
    await _aiService.resetSession();
    _messages.value = [];
    _quickReplies.value = [];
    _preferences.clear();
    _isLoading.value = true;
    _fadeController.reset();
    _initializeChat();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
      appBar: _buildAppBar(isDark),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return _LoadingShimmer(isDark: isDark);
          }
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: _ChatList(
                    messages: _messages,
                    isTyping: _isTyping,
                    scrollController: _scrollController,
                    isDark: isDark,
                    onJoinRoom: _joinRoom,
                    l10n: _l10n,
                  ),
                ),
                _QuickReplies(
                  quickReplies: _quickReplies,
                  isDark: isDark,
                  onTap: _handleQuickReply,
                ),
                _InputArea(
                  controller: _inputController,
                  isDark: isDark,
                  onSend: _sendMessage,
                  l10n: _l10n,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _l10n.subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : Colors.black54),
          onPressed: _restartChat,
        ),
      ],
    );
  }
}

// ============ LOCALIZATION ============

class _AiAssistantLocalizations {
  final String languageCode;
  
  _AiAssistantLocalizations(this.languageCode);
  
  bool get isTurkish => languageCode == 'tr';
  
  String get title => isTurkish ? 'AI Asistan' : 'AI Assistant';
  String get subtitle => isTurkish 
      ? 'Seninle sohbet etmek için buradayım' 
      : 'I\'m here to chat with you';
  String get inputHint => isTurkish ? 'Mesajını yaz...' : 'Type your message...';
  String get connectionError => isTurkish 
      ? 'Sunucuya bağlanılamadı. İnternet bağlantını kontrol et! 🔌' 
      : 'Could not connect to server. Check your internet connection! 🔌';
  String get defaultGreeting => isTurkish 
      ? 'Merhaba! 👋 Bugün nasılsın?' 
      : 'Hello! 👋 How are you today?';
  String get somethingWentWrong => isTurkish 
      ? 'Bir şeyler ters gitti...' 
      : 'Something went wrong...';
  String get tryAgain => isTurkish 
      ? 'Bir sorun oluştu, tekrar dener misin? 🙏' 
      : 'Something went wrong, can you try again? 🙏';
  String get pleaseSignIn => isTurkish ? 'Lütfen giriş yapın' : 'Please sign in';
  String get joiningRoom => isTurkish ? 'Odaya katılınıyor...' : 'Joining room...';
  String joinedRoom(String roomName) => isTurkish 
      ? '🎉 "$roomName" odasına katıldın!' 
      : '🎉 You joined "$roomName"!';
  String get joinError => isTurkish 
      ? 'Katılırken bir hata oluştu' 
      : 'Error while joining';
  String get joinButton => isTurkish ? 'Katıl' : 'Join';
}

// ============ LOADING SHIMMER ============

class _LoadingShimmer extends StatefulWidget {
  final bool isDark;
  const _LoadingShimmer({required this.isDark});

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final shimmerValue = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(MediaQuery.of(context).size.width * 0.6, 50, shimmerValue),
              const SizedBox(height: 12),
              _shimmerBox(MediaQuery.of(context).size.width * 0.4, 40, shimmerValue),
              const SizedBox(height: 24),
              Row(
                children: [
                  _shimmerBox(80, 36, shimmerValue),
                  const SizedBox(width: 8),
                  _shimmerBox(80, 36, shimmerValue),
                  const SizedBox(width: 8),
                  _shimmerBox(80, 36, shimmerValue),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, double shimmerValue) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isDark
            ? Color.lerp(const Color(0xFF16213E), const Color(0xFF1F2B47), shimmerValue)
            : Color.lerp(Colors.grey[200], Colors.grey[100], shimmerValue),
      ),
    );
  }
}

// ============ CHAT LIST ============

class _ChatList extends StatelessWidget {
  final ValueNotifier<List<ChatBubble>> messages;
  final ValueNotifier<bool> isTyping;
  final ScrollController scrollController;
  final bool isDark;
  final Function(String, String) onJoinRoom;
  final _AiAssistantLocalizations l10n;

  const _ChatList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
    required this.isDark,
    required this.onJoinRoom,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ChatBubble>>(
      valueListenable: messages,
      builder: (context, messageList, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isTyping,
          builder: (context, typing, _) {
            final itemCount = messageList.length + (typing ? 1 : 0);
            
            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == messageList.length && typing) {
                  return _TypingIndicator(isDark: isDark);
                }
                
                final message = messageList[index];
                
                if (message.isRoomList && message.rooms != null) {
                  return _RoomCards(
                    rooms: message.rooms!,
                    isDark: isDark,
                    onJoinRoom: onJoinRoom,
                    l10n: l10n,
                  );
                }
                
                return _MessageBubble(
                  key: ValueKey('msg_$index'),
                  message: message, 
                  isDark: isDark,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============ MESSAGE BUBBLE ============

class _MessageBubble extends StatelessWidget {
  final ChatBubble message;
  final bool isDark;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: message.isUser 
                ? const Color(0xFF667EEA)
                : (isDark ? const Color(0xFF16213E) : Colors.white),
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: message.isUser ? const Radius.circular(4) : null,
              bottomLeft: !message.isUser ? const Radius.circular(4) : null,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.text ?? '',
            style: TextStyle(
              color: message.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ============ ROOM CARDS ============

class _RoomCards extends StatelessWidget {
  final List<RoomRecommendation> rooms;
  final bool isDark;
  final Function(String, String) onJoinRoom;
  final _AiAssistantLocalizations l10n;

  const _RoomCards({
    required this.rooms,
    required this.isDark,
    required this.onJoinRoom,
    required this.l10n,
  });

  static const _emojis = {
    'sports': '⚽', 'gaming': '🎮', 'music': '🎵', 'movie': '🎬',
    'study': '📚', 'coding': '💻', 'chat': '💬', 'food': '🍕',
    'yoga': '🧘', 'art': '🎨', 'travel': '✈️', 'fitness': '💪',
    'coffee': '☕', 'photography': '📷', 'outdoor': '🏕️', 'anime': '🎌',
    'podcast': '🎙️', 'cooking': '👨‍🍳', 'crypto': '📈', 'tech': '💡',
    'reading': '📖', 'networking': '🤝',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rooms.asMap().entries.map((entry) {
        final index = entry.key;
        final room = entry.value;
        return TweenAnimationBuilder<double>(
          key: ValueKey('room_${room.id}'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + (index * 80)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildCard(room),
        );
      }).toList(),
    );
  }

  Widget _buildCard(RoomRecommendation room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(_emojis[room.category] ?? '💬', style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${room.participantCount}/${room.maxParticipants}',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              room.matchReason,
                              style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (room.aiExplanation?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              room.aiExplanation!,
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onJoinRoom(room.id, room.name),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(l10n.joinButton, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ TYPING INDICATOR ============

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF16213E) : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
        ),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final phase = index * 0.33;
                final animValue = (_controller.value + phase) % 1.0;
                final opacity = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(animValue * math.pi * 2));
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ============ QUICK REPLIES ============

class _QuickReplies extends StatelessWidget {
  final ValueNotifier<List<QuickReply>> quickReplies;
  final bool isDark;
  final Function(QuickReply) onTap;

  const _QuickReplies({
    required this.quickReplies,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<QuickReply>>(
      valueListenable: quickReplies,
      builder: (context, replies, _) {
        if (replies.isEmpty) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: replies.asMap().entries.map((entry) {
                final index = entry.key;
                final reply = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 150 + (index * 40)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: isDark ? const Color(0xFF16213E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => onTap(reply),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          ),
                          child: Text(
                            reply.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ============ INPUT AREA ============

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Function(String) onSend;
  final _AiAssistantLocalizations l10n;

  const _InputArea({
    required this.controller,
    required this.isDark,
    required this.onSend,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.inputHint,
                  hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) onSend(text);
                },
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    onSend(controller.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ MODEL ============

class ChatBubble {
  final String? text;
  final bool isUser;  
  final bool isRoomList;
  final List<RoomRecommendation>? rooms;

  const ChatBubble({
    this.text,
    required this.isUser,
    this.isRoomList = false,
    this.rooms,
  });
}