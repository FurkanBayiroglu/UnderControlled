import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_room_page.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedCategory = 'all';
  final Map<String, bool> _joiningRooms = {};
  
  final List<CategoryItem> _categories = [
    CategoryItem(id: 'all', name: 'Tümü', icon: Icons.apps, color: Colors.grey, emoji: '🌐'),
    CategoryItem(id: 'sports', name: 'Spor', icon: Icons.sports_soccer, color: Colors.green, emoji: '⚽'),
    CategoryItem(id: 'fitness', name: 'Fitness', icon: Icons.fitness_center, color: Colors.orange, emoji: '💪'),
    CategoryItem(id: 'yoga', name: 'Yoga', icon: Icons.self_improvement, color: Colors.teal, emoji: '🧘'),
    CategoryItem(id: 'gaming', name: 'Oyun', icon: Icons.gamepad, color: Colors.blue, emoji: '🎮'),
    CategoryItem(id: 'esports', name: 'E-Spor', icon: Icons.emoji_events, color: Colors.red, emoji: '🏆'),
    CategoryItem(id: 'board_games', name: 'Masa Oyunu', icon: Icons.casino, color: Colors.brown, emoji: '🎲'),
    CategoryItem(id: 'music', name: 'Müzik', icon: Icons.music_note, color: Colors.purple, emoji: '🎵'),
    CategoryItem(id: 'art', name: 'Sanat', icon: Icons.palette, color: Colors.pink, emoji: '🎨'),
    CategoryItem(id: 'photography', name: 'Fotoğraf', icon: Icons.camera_alt, color: Colors.blueGrey, emoji: '📷'),
    CategoryItem(id: 'dance', name: 'Dans', icon: Icons.nightlife, color: Colors.deepPurple, emoji: '💃'),
    CategoryItem(id: 'study', name: 'Çalışma', icon: Icons.school, color: Colors.indigo, emoji: '📚'),
    CategoryItem(id: 'language', name: 'Dil', icon: Icons.translate, color: Colors.cyan, emoji: '🌍'),
    CategoryItem(id: 'coding', name: 'Kodlama', icon: Icons.code, color: Colors.green, emoji: '💻'),
    CategoryItem(id: 'reading', name: 'Kitap', icon: Icons.menu_book, color: Colors.brown, emoji: '📖'),
    CategoryItem(id: 'chat', name: 'Sohbet', icon: Icons.chat_bubble, color: Colors.teal, emoji: '💬'),
    CategoryItem(id: 'debate', name: 'Tartışma', icon: Icons.forum, color: Colors.deepOrange, emoji: '🗣️'),
    CategoryItem(id: 'movie', name: 'Film', icon: Icons.movie, color: Colors.red, emoji: '🎬'),
    CategoryItem(id: 'anime', name: 'Anime', icon: Icons.auto_awesome, color: Colors.pink, emoji: '🌸'),
    CategoryItem(id: 'food', name: 'Yemek', icon: Icons.restaurant, color: Colors.amber, emoji: '🍕'),
    CategoryItem(id: 'cooking', name: 'Yemek Yapma', icon: Icons.soup_kitchen, color: Colors.orange, emoji: '👨‍🍳'),
    CategoryItem(id: 'coffee', name: 'Kahve', icon: Icons.coffee, color: Colors.brown, emoji: '☕'),
    CategoryItem(id: 'travel', name: 'Seyahat', icon: Icons.flight, color: Colors.lightBlue, emoji: '✈️'),
    CategoryItem(id: 'outdoor', name: 'Outdoor', icon: Icons.terrain, color: Colors.green, emoji: '🏕️'),
    CategoryItem(id: 'tech', name: 'Teknoloji', icon: Icons.computer, color: Colors.blueGrey, emoji: '🖥️'),
    CategoryItem(id: 'crypto', name: 'Kripto', icon: Icons.currency_bitcoin, color: Colors.amber, emoji: '💰'),
    CategoryItem(id: 'pets', name: 'Evcil Hayvan', icon: Icons.pets, color: Colors.orange, emoji: '🐾'),
    CategoryItem(id: 'cars', name: 'Otomobil', icon: Icons.directions_car, color: Colors.red, emoji: '🚗'),
    CategoryItem(id: 'fashion', name: 'Moda', icon: Icons.checkroom, color: Colors.pink, emoji: '👗'),
  ];

  CategoryItem _getCategoryById(String id) {
    return _categories.firstWhere((c) => c.id == id, orElse: () => _categories.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildRoomList()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Etkinlik Odaları', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.category, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Kategoriler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category.id;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category.id),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? category.color : category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected ? [
                              BoxShadow(color: category.color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ] : null,
                          ),
                          child: Center(
                            child: isSelected
                                ? Icon(category.icon, color: Colors.white, size: 26)
                                : Text(category.emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? category.color : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    Query query = FirebaseFirestore.instance.collection('rooms').where('isActive', isEqualTo: true);
    
    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('participantCount', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Bir hata oluştu', style: TextStyle(color: Colors.grey.shade600)),
                TextButton(onPressed: () => setState(() {}), child: const Text('Tekrar Dene')),
              ],
            ),
          );
        }
        
        final rooms = snapshot.data?.docs ?? [];
        
        if (rooms.isEmpty) return _buildEmptyState();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index].data() as Map<String, dynamic>;
            final roomId = rooms[index].id;
            return _buildRoomCard(roomId, room);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final category = _getCategoryById(_selectedCategory);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: category.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(category.icon, size: 48, color: category.color.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedCategory == 'all' ? 'Henüz aktif oda yok' : '${category.name} kategorisinde oda yok',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('İlk odayı sen oluştur!', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateRoom(),
              icon: const Icon(Icons.add),
              label: const Text('Oda Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: category.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_selectedCategory != 'all') ...[
              const SizedBox(height: 12),
              TextButton(onPressed: () => setState(() => _selectedCategory = 'all'), child: const Text('Tüm odaları göster')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(String roomId, Map<String, dynamic> room) {
    final category = _getCategoryById(room['category'] ?? 'chat');
    final participants = List<String>.from(room['participants'] ?? []);
    final maxParticipants = room['maxParticipants'] ?? 20;
    final participantCount = participants.length;
    final isFull = participantCount >= maxParticipants;
    final isJoined = participants.contains(_currentUserId);
    final isJoining = _joiningRooms[roomId] == true;
    final fillPercent = (participantCount / maxParticipants * 100).round();
    
    Color statusColor;
    String statusText;
    if (isJoined) {
      statusColor = Colors.green;
      statusText = 'Katıldın';
    } else if (isFull) {
      statusColor = Colors.red;
      statusText = 'Dolu';
    } else if (fillPercent > 70) {
      statusColor = Colors.orange;
      statusText = 'Dolmak üzere';
    } else {
      statusColor = Colors.green;
      statusText = 'Açık';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isJoined ? Border.all(color: Colors.green.shade400, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: (isJoined || isFull || isJoining) ? null : () => _joinRoom(roomId, room),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: category.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(category.name, style: TextStyle(color: category.color, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [category.color.withOpacity(0.8), category.color]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: category.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Icon(category.icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room['name'] ?? 'İsimsiz Oda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (room['description'] != null && room['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(room['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text('$participantCount / $maxParticipants kişi', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: participantCount / maxParticipants,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(isFull ? Colors.red : fillPercent > 70 ? Colors.orange : Colors.green),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: (isJoined || isFull || isJoining) ? null : () => _joinRoom(roomId, room),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isJoined ? Colors.green : isFull ? Colors.grey.shade400 : category.color,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isJoined ? Colors.green : Colors.grey.shade300,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isJoining
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isJoined ? Icons.check_circle : isFull ? Icons.block : Icons.login, size: 18),
                                  const SizedBox(width: 6),
                                  Text(isJoined ? 'Katıldın' : isFull ? 'Dolu' : 'Katıl', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreateRoom(),
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.add),
      label: const Text('Oda Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _navigateToCreateRoom() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomPage()));
  }

  Future<void> _joinRoom(String roomId, Map<String, dynamic> room) async {
    if (_joiningRooms[roomId] == true) return;
    
    setState(() => _joiningRooms[roomId] = true);
    
    try {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
      final roomDoc = await roomRef.get();
      
      if (!roomDoc.exists) throw Exception('Oda bulunamadı');
      
      final roomData = roomDoc.data()!;
      final participants = List<String>.from(roomData['participants'] ?? []);
      final maxParticipants = roomData['maxParticipants'] ?? 20;
      
      if (participants.contains(_currentUserId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.info, color: Colors.white), SizedBox(width: 8), Text('Zaten bu odadasın!')]),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
      
      if (participants.length >= maxParticipants) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.error, color: Colors.white), SizedBox(width: 8), Text('Oda dolu!')]),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
      
      await roomRef.update({
        'participants': FieldValue.arrayUnion([_currentUserId]),
        'participantCount': FieldValue.increment(1),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text('${room['name']} odasına katıldın! 🎉'))]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _joiningRooms[roomId] = false);
    }
  }
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  const CategoryItem({required this.id, required this.name, required this.icon, required this.color, required this.emoji});
}