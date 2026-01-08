import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilter({super.key, required this.selectedCategory, required this.onCategorySelected});

  static const List<Map<String, dynamic>> categories = [
    {'id': 'all', 'name_tr': 'Tümü', 'name_en': 'All', 'icon': Icons.apps_rounded, 'color': Color(0xFF667EEA)},
    {'id': 'sports', 'name_tr': 'Spor', 'name_en': 'Sports', 'icon': Icons.sports_soccer_rounded, 'color': Color(0xFF10B981)},
    {'id': 'gaming', 'name_tr': 'Oyun', 'name_en': 'Gaming', 'icon': Icons.sports_esports_rounded, 'color': Color(0xFF3B82F6)},
    {'id': 'music', 'name_tr': 'Müzik', 'name_en': 'Music', 'icon': Icons.music_note_rounded, 'color': Color(0xFF8B5CF6)},
    {'id': 'study', 'name_tr': 'Çalışma', 'name_en': 'Study', 'icon': Icons.school_rounded, 'color': Color(0xFFF59E0B)},
    {'id': 'chat', 'name_tr': 'Sohbet', 'name_en': 'Chat', 'icon': Icons.chat_bubble_rounded, 'color': Color(0xFF06B6D4)},
    {'id': 'movie', 'name_tr': 'Film', 'name_en': 'Movie', 'icon': Icons.movie_rounded, 'color': Color(0xFFEF4444)},
    {'id': 'food', 'name_tr': 'Yemek', 'name_en': 'Food', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFF97316)},
    {'id': 'tech', 'name_tr': 'Teknoloji', 'name_en': 'Tech', 'icon': Icons.computer_rounded, 'color': Color(0xFF6366F1)},
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];
          final color = category['color'] as Color;
          return GestureDetector(
            onTap: () => onCategorySelected(category['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [color.withOpacity(0.8), color]) : null,
                color: isSelected ? null : AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isSelected ? color : AppTheme.border(context), width: isSelected ? 0 : 1),
                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category['icon'] as IconData, size: 18, color: isSelected ? Colors.white : AppTheme.textSecondary(context)),
                  const SizedBox(width: 8),
                  Text(locale.isTurkish ? category['name_tr'] : category['name_en'], style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
