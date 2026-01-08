import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/premium/premium_service.dart';

class ProfileHeader extends StatelessWidget {
  final User? user;
  final Map<String, dynamic> userData;
  const ProfileHeader({super.key, this.user, required this.userData});

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? userData['name'] ?? 'User';
    final username = userData['username'] ?? '';
    final photoUrl = userData['photoUrl'] as String?;
    final premiumService = context.watch<PremiumService>();
    final isPremium = premiumService.isPremium;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPremium 
                    ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                    : AppTheme.primaryGradient,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.surface(context),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null 
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?', 
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      )
                    : null,
              ),
            ),
            // Premium rozeti
            if (isPremium)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface(context), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.diamond_rounded, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text('@$username', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary(context))),
      ],
    );
  }
}
