import 'package:flutter/material.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Aktif sohbet ID'si - bu sohbetteyken bildirim gösterme
  String? _activeConversationId;
  
  // Overlay entry referansı
  OverlayEntry? _currentOverlay;
  
  // Getter/Setter
  String? get activeConversationId => _activeConversationId;
  
  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
    print('📍 Aktif sohbet: $conversationId');
  }
  
  void clearActiveConversation() {
    _activeConversationId = null;
    print('📍 Aktif sohbet temizlendi');
  }
  
  // Bu conversation için bildirim gösterilmeli mi?
  bool shouldShowNotification(String? conversationId) {
    if (conversationId == null) return true;
    if (_activeConversationId == null) return true;
    return _activeConversationId != conversationId;
  }
  
  // Üstten banner bildirimi göster
  void showTopBanner({
    required BuildContext context,
    required String title,
    required String body,
    required String type,
    VoidCallback? onTap,
  }) {
    // Önceki bildirimi kapat
    _currentOverlay?.remove();
    _currentOverlay = null;
    
    final overlay = Overlay.of(context);
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _TopBannerNotification(
        title: title,
        body: body,
        type: type,
        onTap: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          onTap?.call();
        },
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );
    
    overlay.insert(_currentOverlay!);
    
    // 4 saniye sonra otomatik kapat
    Future.delayed(const Duration(seconds: 4), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }
}

// Üstten gelen banner widget
class _TopBannerNotification extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _TopBannerNotification({
    required this.title,
    required this.body,
    required this.type,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_TopBannerNotification> createState() => _TopBannerNotificationState();
}

class _TopBannerNotificationState extends State<_TopBannerNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMessage = widget.type == 'message';
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              widget.onDismiss?.call();
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              top: statusBarHeight + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMessage
                    ? [Colors.blue.shade600, Colors.blue.shade400]
                    : [Colors.purple.shade600, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // İkon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMessage ? Icons.message : Icons.person_add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Metin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Kapat butonu
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}