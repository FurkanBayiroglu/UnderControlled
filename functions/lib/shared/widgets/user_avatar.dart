import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Profil fotoğrafı gösteren yeniden kullanılabilir avatar widget'ı
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showOnlineIndicator;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.primary.withOpacity(0.1);
    final fgColor = textColor ?? AppTheme.primary;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget avatar;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      );
    }

    if (!showOnlineIndicator) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.4,
            height: radius * 0.4,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.success : AppTheme.textTertiary(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.surface(context),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grup/Oda için avatar widget'ı
class GroupAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String category;
  final double size;

  const GroupAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.category = 'chat',
    this.size = 56,
  });

  static const Map<String, Color> categoryColors = {
    'sports': Color(0xFF10B981),
    'gaming': Color(0xFF3B82F6),
    'music': Color(0xFF8B5CF6),
    'study': Color(0xFFF59E0B),
    'chat': Color(0xFF06B6D4),
    'movie': Color(0xFFEF4444),
    'food': Color(0xFFF97316),
    'tech': Color(0xFF6366F1),
    'travel': Color(0xFF0EA5E9),
  };

  static const Map<String, IconData> categoryIcons = {
    'sports': Icons.sports_soccer_rounded,
    'gaming': Icons.sports_esports_rounded,
    'music': Icons.music_note_rounded,
    'study': Icons.school_rounded,
    'chat': Icons.chat_bubble_rounded,
    'movie': Icons.movie_rounded,
    'food': Icons.restaurant_rounded,
    'tech': Icons.computer_rounded,
    'travel': Icons.flight_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[category] ?? const Color(0xFF6B7280);
    final icon = categoryIcons[category] ?? Icons.group_rounded;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}