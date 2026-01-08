import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';

class RoomCardWidget extends StatelessWidget {
  final String roomId, name, description, category;
  final int participantCount, maxParticipants;
  final bool isJoined;
  final VoidCallback onTap, onJoinTap, onLeaveTap;

  const RoomCardWidget({super.key, required this.roomId, required this.name, required this.description, required this.category, required this.participantCount, required this.maxParticipants, required this.isJoined, required this.onTap, required this.onJoinTap, required this.onLeaveTap});

  static const Map<String, Color> categoryColors = {'sports': Color(0xFF10B981), 'gaming': Color(0xFF3B82F6), 'music': Color(0xFF8B5CF6), 'study': Color(0xFFF59E0B), 'chat': Color(0xFF06B6D4), 'movie': Color(0xFFEF4444), 'food': Color(0xFFF97316), 'tech': Color(0xFF6366F1), 'art': Color(0xFFEC4899)};
  static const Map<String, IconData> categoryIcons = {'sports': Icons.sports_soccer_rounded, 'gaming': Icons.sports_esports_rounded, 'music': Icons.music_note_rounded, 'study': Icons.school_rounded, 'chat': Icons.chat_bubble_rounded, 'movie': Icons.movie_rounded, 'food': Icons.restaurant_rounded, 'tech': Icons.computer_rounded, 'art': Icons.palette_rounded};

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final color = categoryColors[category] ?? AppTheme.primary;
    final icon = categoryIcons[category] ?? Icons.group_rounded;
    final isFull = participantCount >= maxParticipants;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isJoined ? color.withOpacity(0.5) : AppTheme.border(context), width: isJoined ? 2 : 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color]), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 22)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: isFull ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_rounded, size: 14, color: isFull ? AppTheme.error : AppTheme.success),
                        const SizedBox(width: 4),
                        Text('$participantCount/$maxParticipants', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isFull ? AppTheme.error : AppTheme.success)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary(context)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Expanded(child: Text(description, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(height: 12),
                _buildActionButton(context, locale, color, isFull),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, LocaleProvider locale, Color color, bool isFull) {
    if (isJoined) {
      return Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color]), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(locale.get('enter'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onLeaveTap,
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.exit_to_app_rounded, color: AppTheme.error, size: 18)),
        ),
      ]);
    }
    return GestureDetector(
      onTap: isFull ? null : onJoinTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(gradient: isFull ? null : LinearGradient(colors: [color.withOpacity(0.8), color]), color: isFull ? AppTheme.surfaceVariant(context) : null, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(isFull ? locale.get('full') : locale.get('join'), style: TextStyle(color: isFull ? AppTheme.textTertiary(context) : Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
      ),
    );
  }
}
