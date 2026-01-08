import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';

class RoomMembers extends StatelessWidget {
  final List<String> participants;
  final String ownerId;

  const RoomMembers({
    super.key,
    required this.participants,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return Container(
      color: AppTheme.background(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final userId = participants[index];
          final isOwner = userId == ownerId;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(locale.get('loading'), style: TextStyle(color: AppTheme.textSecondary(context))),
                    ],
                  ),
                );
              }

              if (!snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final name = userData['name'] ?? locale.get('anonymous');
              final username = userData['username'] ?? '';
              final photoUrl = userData['photoUrl'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            locale.get('founder'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('@$username', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                  trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary(context)),
                  onTap: () {
                    // Profil sayfasına git
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}