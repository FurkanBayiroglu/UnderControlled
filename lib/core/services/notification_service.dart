import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    VoidCallback? onMarkAsRead,
  }) {
    // Önceki bildirimi kapat
    _currentOverlay?.remove();
    _currentOverlay = null;
    
    final overlay = Overlay.of(context);
    
    _currentOverlay = OverlayEntry(
      builder: (ctx) => _TopBannerNotification(
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
        onMarkAsRead: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          onMarkAsRead?.call();
        },
      ),
    );
    
    overlay.insert(_currentOverlay!);
    
    // 5 saniye sonra otomatik kapat
    Future.delayed(const Duration(seconds: 5), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }
  
  // Bildirimi kapat
  void dismissBanner() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

// Üstten gelen banner widget
class _TopBannerNotification extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onMarkAsRead;

  const _TopBannerNotification({
    required this.title,
    required this.body,
    required this.type,
    this.onTap,
    this.onDismiss,
    this.onMarkAsRead,
  });

  @override
  State<_TopBannerNotification> createState() => _TopBannerNotificationState();
}

class _TopBannerNotificationState extends State<_TopBannerNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
    final isFollowRequest = widget.type == 'follow_request' || widget.type == 'follow';
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = AppTheme.isDark(context);
    
    // Dark mode'a göre renkler
    final List<Color> gradientColors;
    final Color iconBgColor;
    final Color textColor;
    final Color subtitleColor;
    final Color buttonBgColor;
    final Color buttonTextColor;
    
    if (isDark) {
      // Dark mode renkleri
      if (isMessage) {
        gradientColors = [const Color(0xFF1E3A5F), const Color(0xFF0D2137)];
      } else if (isFollowRequest) {
        gradientColors = [const Color(0xFF4A1D6A), const Color(0xFF2D1340)];
      } else {
        gradientColors = [const Color(0xFF1A472A), const Color(0xFF0D2818)];
      }
      iconBgColor = Colors.white.withOpacity(0.1);
      textColor = Colors.white;
      subtitleColor = Colors.white70;
      buttonBgColor = Colors.white.withOpacity(0.15);
      buttonTextColor = Colors.white;
    } else {
      // Light mode renkleri
      if (isMessage) {
        gradientColors = [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      } else if (isFollowRequest) {
        gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];
      } else {
        gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
      }
      iconBgColor = Colors.white.withOpacity(0.2);
      textColor = Colors.white;
      subtitleColor = Colors.white.withOpacity(0.85);
      buttonBgColor = Colors.white.withOpacity(0.2);
      buttonTextColor = Colors.white;
    }
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                widget.onDismiss?.call();
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                top: statusBarHeight + 8,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // İkon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isMessage 
                                    ? Icons.message_rounded 
                                    : isFollowRequest 
                                        ? Icons.person_add_rounded 
                                        : Icons.notifications_rounded,
                                color: textColor,
                                size: 22,
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
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.body,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Kapat butonu
                            GestureDetector(
                              onTap: widget.onDismiss,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: textColor.withOpacity(0.7),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Alt butonlar
                        Row(
                          children: [
                            // Oku butonu
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.onMarkAsRead,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: buttonBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.done_rounded,
                                        color: buttonTextColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Okundu',
                                        style: TextStyle(
                                          color: buttonTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Görüntüle butonu
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.onTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isMessage ? Icons.chat_rounded : Icons.visibility_rounded,
                                        color: gradientColors[0],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isMessage ? 'Yanıtla' : 'Görüntüle',
                                        style: TextStyle(
                                          color: gradientColors[0],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}