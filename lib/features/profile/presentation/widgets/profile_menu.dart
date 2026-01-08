import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/premium/premium_service.dart';
import '../../../social/presentation/pages/follow_requests_page.dart';
import '../../../premium/presentation/pages/premium_page.dart';
import '../pages/edit_profile_page.dart';

class ProfileMenu extends StatelessWidget {
  final User? user;
  final Map<String, dynamic> userData;
  const ProfileMenu({super.key, this.user, required this.userData});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final premiumService = context.watch<PremiumService>();
    final followRequests = (userData['followRequests'] as List?)?.length ?? 0;

    return Column(
      children: [
        // Premium Banner (Premium değilse göster)
        if (!premiumService.isPremium) ...[
          _PremiumBanner(locale: locale),
          const SizedBox(height: 16),
        ],
        
        // Premium Durum Kartı (Premium ise göster)
        if (premiumService.isPremium) ...[
          _PremiumStatusCard(premiumService: premiumService, locale: locale),
          const SizedBox(height: 16),
        ],

        Container(
          decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border(context))),
          child: Column(
            children: [
              // Premium ise premium yönetim menüsü
              if (premiumService.isPremium) ...[
                _MenuItem(
                  icon: Icons.diamond_rounded, 
                  label: locale.get('premium'), 
                  color: const Color(0xFFFFD700), 
                  isPremium: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage())),
                ),
                _Divider(),
              ],
              _MenuItem(
                icon: Icons.person_add_rounded,
                label: locale.get('followRequests'),
                color: const Color(0xFFF59E0B),
                badge: followRequests > 0 ? followRequests.toString() : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowRequestsPage())),
              ),
              _Divider(),
              _MenuItem(
                icon: Icons.edit_rounded, 
                label: locale.get('editProfile'), 
                color: const Color(0xFF8B5CF6), 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
              ),
              _Divider(),
              _MenuItem(icon: Icons.settings_rounded, label: locale.get('settings'), color: const Color(0xFF6B7280), onTap: () {}),
              _Divider(),
              _MenuItem(icon: Icons.privacy_tip_rounded, label: locale.get('privacy'), color: const Color(0xFF10B981), onTap: () {}),
              _Divider(),
              _MenuItem(icon: Icons.logout_rounded, label: locale.get('logout'), color: AppTheme.error, onTap: () async => await FirebaseAuth.instance.signOut()),
            ],
          ),
        ),
      ],
    );
  }
}

// Premium Banner - Kullanıcıyı premium'a davet eder
class _PremiumBanner extends StatelessWidget {
  final LocaleProvider locale;
  const _PremiumBanner({required this.locale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00B6F0), Color(0xFF2633C5)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B6F0).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.get('goPremium'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale.get('premiumSubtitle'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Durum Kartı - Premium kullanıcılar için
class _PremiumStatusCard extends StatelessWidget {
  final PremiumService premiumService;
  final LocaleProvider locale;
  const _PremiumStatusCard({required this.premiumService, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        locale.get('active'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${premiumService.status.daysRemaining} ${locale.get('daysRemaining')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final bool isPremium;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.color, this.badge, this.isPremium = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(
          color: isPremium ? null : color.withOpacity(0.1), 
          gradient: isPremium ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]) : null,
          borderRadius: BorderRadius.circular(12),
        ), 
        child: Icon(icon, color: isPremium ? Colors.white : color, size: 22),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
      trailing: badge != null
          ? Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle), child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))
          : Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textTertiary(context)),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 70, color: AppTheme.border(context));
}
