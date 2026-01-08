import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../social/presentation/pages/follow_requests_page.dart';
import '../../data/services/profile_service.dart';

class ProfileMenu extends StatelessWidget {
  final String userId;
  final _profileService = ProfileService();
  
  ProfileMenu({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        
        // Takip İstekleri
        _buildMenuItem(
          context: context,
          icon: Icons.person_add,
          iconColor: Colors.blue,
          title: 'Takip İstekleri',
          trailing: _buildRequestsBadge(),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FollowRequestsPage()),
            );
          },
        ),
        
        // Profili Düzenle
        _buildMenuItem(
          context: context,
          icon: Icons.edit,
          iconColor: Colors.green,
          title: 'Profili Düzenle',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yakında eklenecek!')),
            );
          },
        ),
        
        // Ayarlar
        _buildMenuItem(
          context: context,
          icon: Icons.settings,
          iconColor: Colors.grey,
          title: 'Ayarlar',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yakında eklenecek!')),
            );
          },
        ),
        
        // Gizlilik
        _buildMenuItem(
          context: context,
          icon: Icons.lock_outline,
          iconColor: Colors.orange,
          title: 'Gizlilik',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yakında eklenecek!')),
            );
          },
        ),
        
        const Divider(),
        
        // Çıkış Yap
        _buildMenuItem(
          context: context,
          icon: Icons.logout,
          iconColor: Colors.red,
          title: 'Çıkış Yap',
          titleColor: Colors.red,
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }
  
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  Widget _buildRequestsBadge() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final requests = (data?['followRequests'] as List?)?.length ?? 0;
        
        if (requests == 0) {
          return const Icon(Icons.arrow_forward_ios, size: 16);
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            requests.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _profileService.signOut(); // Service kullanıyoruz
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}