import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../data/services/follow_service.dart';

class FollowRequestsPage extends StatelessWidget {
  final _followService = FollowService();
  FollowRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary(context)), onPressed: () => Navigator.pop(context)),
        title: Text(locale.get('followRequests'), style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _followService.getFollowRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.person_add_disabled_rounded, size: 48, color: AppTheme.primary)),
              const SizedBox(height: 20),
              Text(locale.get('noFollowRequests'), style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 16)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final user = requests[index];
              return _RequestCard(user: user, followService: _followService);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final FollowService followService;
  const _RequestCard({required this.user, required this.followService});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Text((user['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
        title: Text(user['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        subtitle: Text('@${user['username'] ?? ''}', style: TextStyle(color: AppTheme.textSecondary(context))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 20)),
              onPressed: () async => await followService.acceptFollowRequest(user['id']),
            ),
            IconButton(
              icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.close_rounded, color: AppTheme.error, size: 20)),
              onPressed: () async => await followService.rejectFollowRequest(user['id']),
            ),
          ],
        ),
      ),
    );
  }
}
