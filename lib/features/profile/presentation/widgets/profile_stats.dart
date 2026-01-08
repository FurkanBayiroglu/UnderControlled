import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../social/presentation/pages/followers_list_page.dart';

class ProfileStats extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfileStats({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final followers = (userData['followers'] as List?)?.length ?? 0;
    final following = (userData['following'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border(context))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            count: followers.toString(),
            label: locale.get('followers'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowersListPage(
                  userId: user?.uid ?? '',
                  userName: user?.displayName ?? userData['name'] ?? 'User',
                  showFollowers: true,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.border(context)),
          _StatItem(
            count: following.toString(),
            label: locale.get('following'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowersListPage(
                  userId: user?.uid ?? '',
                  userName: user?.displayName ?? userData['name'] ?? 'User',
                  showFollowers: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count, label;
  final VoidCallback onTap;
  const _StatItem({required this.count, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}
