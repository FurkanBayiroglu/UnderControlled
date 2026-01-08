import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../social/presentation/pages/followers_list_page.dart';

class ProfileStats extends StatelessWidget {
  final String userId;
  final String userName;
  
  const ProfileStats({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 60);
        }
        
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final followers = (userData['followers'] as List?)?.length ?? 0;
        final following = (userData['following'] as List?)?.length ?? 0;
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatItem(
                label: 'Takipçi',
                count: followers,
                onTap: () => _navigateToFollowers(context, true),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              _StatItem(
                label: 'Takip',
                count: following,
                onTap: () => _navigateToFollowers(context, false),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _navigateToFollowers(BuildContext context, bool showFollowers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersListPage(
          userId: userId,
          userName: userName,
          showFollowers: showFollowers,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  
  const _StatItem({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}