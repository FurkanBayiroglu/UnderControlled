import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../social/presentation/pages/user_search_page.dart';
import '../pages/notifications_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final locale = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.isDark(context)
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D1117)]
              : [const Color(0xFF00B6F0), const Color(0xFF2633C5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${locale.get('hello')} 👋', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
              const SizedBox(height: 4),
              Text(user?.displayName ?? locale.get('user'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
          Row(
            children: [
              _HeaderButton(
                child: Text(locale.flag, style: const TextStyle(fontSize: 18)),
                onTap: () => _showLanguageDialog(context, locale),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                child: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white, size: 20),
                onTap: () => themeProvider.toggleTheme(),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSearchPage())),
              ),
              const SizedBox(width: 8),
              _NotificationButton(userId: user?.uid ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider locale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: const Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppTheme.border(context), borderRadius: BorderRadius.circular(2))),
            Text(locale.get('selectLanguage'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 20),
            _LanguageOption(name: 'Türkçe', flag: '🇹🇷', langCode: 'tr', locale: locale),
            const SizedBox(height: 12),
            _LanguageOption(name: 'English', flag: '🇺🇸', langCode: 'en', locale: locale),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HeaderButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: child,
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final String userId;
  const _NotificationButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return _HeaderButton(
        child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
        onTap: () {},
      );
    }

    return StreamBuilder<int>(
      stream: _getTotalNotificationCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
                if (count > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<int> _getTotalNotificationCount(String userId) {
    // Birden fazla stream'i birleştir
    final userStream = FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();

    return userStream.asyncMap((userDoc) async {
      int count = 0;
      
      // 1. Takip istekleri
      final userData = userDoc.data();
      if (userData != null) {
        final followRequests = userData['followRequests'] as List?;
        count += followRequests?.length ?? 0;
      }
      
      // 2. Okunmamış bildirimler
      try {
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        count += notifications.docs.length;
      } catch (e) {
        // Bildirim koleksiyonu yoksa devam et
      }
      
      // 3. Okunmamış mesajlar
      try {
        final conversations = await FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: userId)
            .get();
        
        for (var conv in conversations.docs) {
          final unreadCount = conv.data()['unreadCount'] as Map<String, dynamic>?;
          if (unreadCount != null && unreadCount[userId] != null) {
            count += (unreadCount[userId] as int?) ?? 0;
          }
        }
      } catch (e) {
        // Hata olursa devam et
      }
      
      return count;
    });
  }
}

class _LanguageOption extends StatelessWidget {
  final String name, flag, langCode;
  final LocaleProvider locale;
  const _LanguageOption({required this.name, required this.flag, required this.langCode, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isSelected = locale.currentLanguage == langCode;
    return GestureDetector(
      onTap: () { locale.setLanguage(langCode); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border(context), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
