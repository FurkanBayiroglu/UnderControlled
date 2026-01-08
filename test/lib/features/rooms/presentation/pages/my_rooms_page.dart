import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_room_page.dart';

class MyRoomsPage extends StatefulWidget {
  const MyRoomsPage({super.key});

  @override
  State<MyRoomsPage> createState() => _MyRoomsPageState();
}

class _MyRoomsPageState extends State<MyRoomsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Map<String, bool> _leavingRooms = {};
  final Map<String, bool> _deletingRooms = {};

  final Map<String, CategoryInfo> _categories = {
    'sports': CategoryInfo(name: 'Spor', icon: Icons.sports_soccer, color: Colors.green, emoji: '⚽'),
    'fitness': CategoryInfo(name: 'Fitness', icon: Icons.fitness_center, color: Colors.orange, emoji: '💪'),
    'yoga': CategoryInfo(name: 'Yoga', icon: Icons.self_improvement, color: Colors.teal, emoji: '🧘'),
    'gaming': CategoryInfo(name: 'Oyun', icon: Icons.gamepad, color: Colors.blue, emoji: '🎮'),
    'esports': CategoryInfo(name: 'E-Spor', icon: Icons.emoji_events, color: Colors.red, emoji: '🏆'),
    'board_games': CategoryInfo(name: 'Masa Oyunu', icon: Icons.casino, color: Colors.brown, emoji: '🎲'),
    'music': CategoryInfo(name: 'Müzik', icon: Icons.music_note, color: Colors.purple, emoji: '🎵'),
    'art': CategoryInfo(name: 'Sanat', icon: Icons.palette, color: Colors.pink, emoji: '🎨'),
    'photography': CategoryInfo(name: 'Fotoğraf', icon: Icons.camera_alt, color: Colors.blueGrey, emoji: '📷'),
    'dance': CategoryInfo(name: 'Dans', icon: Icons.nightlife, color: Colors.deepPurple, emoji: '💃'),
    'study': CategoryInfo(name: 'Çalışma', icon: Icons.school, color: Colors.indigo, emoji: '📚'),
    'language': CategoryInfo(name: 'Dil', icon: Icons.translate, color: Colors.cyan, emoji: '🌍'),
    'coding': CategoryInfo(name: 'Kodlama', icon: Icons.code, color: Colors.green, emoji: '💻'),
    'reading': CategoryInfo(name: 'Kitap', icon: Icons.menu_book, color: Colors.brown, emoji: '📖'),
    'chat': CategoryInfo(name: 'Sohbet', icon: Icons.chat_bubble, color: Colors.teal, emoji: '💬'),
    'debate': CategoryInfo(name: 'Tartışma', icon: Icons.forum, color: Colors.deepOrange, emoji: '🗣️'),
    'movie': CategoryInfo(name: 'Film', icon: Icons.movie, color: Colors.red, emoji: '🎬'),
    'anime': CategoryInfo(name: 'Anime', icon: Icons.auto_awesome, color: Colors.pink, emoji: '🌸'),
    'food': CategoryInfo(name: 'Yemek', icon: Icons.restaurant, color: Colors.amber, emoji: '🍕'),
    'cooking': CategoryInfo(name: 'Yemek Yapma', icon: Icons.soup_kitchen, color: Colors.orange, emoji: '👨‍🍳'),
    'coffee': CategoryInfo(name: 'Kahve', icon: Icons.coffee, color: Colors.brown, emoji: '☕'),
    'travel': CategoryInfo(name: 'Seyahat', icon: Icons.flight, color: Colors.lightBlue, emoji: '✈️'),
    'outdoor': CategoryInfo(name: 'Outdoor', icon: Icons.terrain, color: Colors.green, emoji: '🏕️'),
    'tech': CategoryInfo(name: 'Teknoloji', icon: Icons.computer, color: Colors.blueGrey, emoji: '🖥️'),
    'crypto': CategoryInfo(name: 'Kripto', icon: Icons.currency_bitcoin, color: Colors.amber, emoji: '💰'),
    'pets': CategoryInfo(name: 'Evcil Hayvan', icon: Icons.pets, color: Colors.orange, emoji: '🐾'),
    'cars': CategoryInfo(name: 'Otomobil', icon: Icons.directions_car, color: Colors.red, emoji: '🚗'),
    'fashion': CategoryInfo(name: 'Moda', icon: Icons.checkroom, color: Colors.pink, emoji: '👗'),
    'networking': CategoryInfo(name: 'Networking', icon: Icons.people, color: Colors.blue, emoji: '🤝'),
    'podcast': CategoryInfo(name: 'Podcast', icon: Icons.podcasts, color: Colors.purple, emoji: '🎙️'),
  };

  CategoryInfo _getCategoryInfo(String? categoryId) {
    return _categories[categoryId] ?? CategoryInfo(name: 'Diğer', icon: Icons.category, color: Colors.grey, emoji: '📌');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Odalarım', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Katıldıklarım'),
            Tab(icon: Icon(Icons.create), text: 'Oluşturduklarım'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildJoinedRooms(), _buildCreatedRooms()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomPage())),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Oda', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildJoinedRooms() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').where('participants', arrayContains: _currentUserId).where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final rooms = snapshot.data?.docs ?? [];
        final joinedRooms = rooms.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['createdBy'] != _currentUserId;
        }).toList();

        if (joinedRooms.isEmpty) {
          return _buildEmptyState(
            icon: Icons.meeting_room_outlined,
            title: 'Henüz bir odaya katılmadın',
            subtitle: 'Etkinlik odalarını keşfet ve katıl!',
            buttonText: 'Odaları Keşfet',
            onButtonPressed: () => Navigator.pop(context),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: joinedRooms.length,
          itemBuilder: (context, index) {
            final room = joinedRooms[index].data() as Map<String, dynamic>;
            final roomId = joinedRooms[index].id;
            return _buildJoinedRoomCard(roomId, room);
          },
        );
      },
    );
  }

  Widget _buildCreatedRooms() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').where('createdBy', isEqualTo: _currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final rooms = snapshot.data?.docs ?? [];

        if (rooms.isEmpty) {
          return _buildEmptyState(
            icon: Icons.add_circle_outline,
            title: 'Henüz oda oluşturmadın',
            subtitle: 'İlk odanı oluştur ve insanları davet et!',
            buttonText: 'Oda Oluştur',
            onButtonPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomPage())),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index].data() as Map<String, dynamic>;
            final roomId = rooms[index].id;
            return _buildCreatedRoomCard(roomId, room);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle, required String buttonText, required VoidCallback onButtonPressed}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: Colors.blue.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedRoomCard(String roomId, Map<String, dynamic> room) {
    final category = _getCategoryInfo(room['category']);
    final participants = List<String>.from(room['participants'] ?? []);
    final maxParticipants = room['maxParticipants'] ?? 20;
    final isLeaving = _leavingRooms[roomId] == true;
    final isActive = room['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? Colors.green.shade200 : Colors.grey.shade300, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: category.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(category.emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(room['name'] ?? 'İsimsiz Oda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(isActive ? 'Aktif' : 'Kapalı', style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(category.name, style: TextStyle(color: category.color, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('${participants.length}/$maxParticipants', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (room['description'] != null && room['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(room['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: isLeaving ? null : () => _leaveRoom(roomId, room['name']),
                icon: isLeaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout, size: 18),
                label: Text(isLeaving ? 'Ayrılıyor...' : 'Odadan Ayrıl'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatedRoomCard(String roomId, Map<String, dynamic> room) {
    final category = _getCategoryInfo(room['category']);
    final participants = List<String>.from(room['participants'] ?? []);
    final maxParticipants = room['maxParticipants'] ?? 20;
    final isDeleting = _deletingRooms[roomId] == true;
    final isActive = room['isActive'] ?? true;
    final fillPercent = (participants.length / maxParticipants * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [category.color.withOpacity(0.8), category.color]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: category.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Oda Sahibi', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(isActive ? 'Aktif' : 'Kapalı', style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(room['name'] ?? 'İsimsiz Oda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${category.emoji} ${category.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            if (room['description'] != null && room['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(room['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text('${participants.length} / $maxParticipants katılımcı', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Text('%$fillPercent dolu', style: TextStyle(color: fillPercent > 70 ? Colors.orange : Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: participants.length / maxParticipants,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(fillPercent > 70 ? Colors.orange : Colors.green),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Düzenleme özelliği yakında!'), backgroundColor: Colors.orange)),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Düzenle'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDeleting ? null : () => _confirmDeleteRoom(roomId, room['name']),
                    icon: isDeleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.delete, size: 18),
                    label: Text(isDeleting ? 'Siliniyor...' : 'Odayı Sil'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveRoom(String roomId, String? roomName) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Odadan Ayrıl'),
        content: Text('${roomName ?? 'Bu oda'}\'dan ayrılmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Ayrıl')),
        ],
      ),
    );

    if (shouldLeave != true) return;

    setState(() => _leavingRooms[roomId] = true);

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'participants': FieldValue.arrayRemove([_currentUserId]),
        'participantCount': FieldValue.increment(-1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Odadan ayrıldın'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _leavingRooms[roomId] = false);
    }
  }

  Future<void> _confirmDeleteRoom(String roomId, String? roomName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.warning_amber, color: Colors.red.shade400), const SizedBox(width: 8), const Text('Odayı Sil')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${roomName ?? 'Bu oda'}\'yı silmek istediğine emin misin?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [Icon(Icons.info_outline, size: 18, color: Colors.red.shade400), const SizedBox(width: 8), const Expanded(child: Text('Bu işlem geri alınamaz!', style: TextStyle(fontSize: 13)))]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Evet, Sil')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _deletingRooms[roomId] = true);

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Oda silindi'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _deletingRooms[roomId] = false);
    }
  }
}

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  const CategoryInfo({required this.name, required this.icon, required this.color, required this.emoji});
}