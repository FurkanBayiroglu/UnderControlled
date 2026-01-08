import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/models/room_model.dart';
import '../../data/services/room_service.dart';
import '../widgets/room_members.dart';
import '../widgets/room_chat.dart';

class RoomDetailPage extends StatefulWidget {
  final String roomId;

  const RoomDetailPage({super.key, required this.roomId});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _roomService = RoomService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
    return StreamBuilder<RoomModel?>(
      stream: _roomService.getRoomStream(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final room = snapshot.data;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Oda')),
            body: const Center(child: Text('Oda bulunamadı')),
          );
        }

        final isOwner = room.createdBy == _currentUserId;
        final isMember = room.participants.contains(_currentUserId);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: _getCategoryColor(room.category),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(room.category),
                            _getCategoryColor(room.category).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(room.category),
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (isOwner)
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(value, room),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'close',
                            child: Row(
                              children: [
                                Icon(Icons.close, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Odayı Kapat'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Odayı Sil'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildRoomInfo(room, isOwner, isMember),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.people),
                          text: 'Katılımcılar (${room.participants.length})',
                        ),
                        const Tab(
                          icon: Icon(Icons.chat),
                          text: 'Sohbet',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                RoomMembers(
                  participants: room.participants,
                  ownerId: room.createdBy,
                ),
                RoomChat(
                  roomId: widget.roomId,
                  isActive: room.isActive && !room.isExpired,
                  isMember: isMember,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomInfo(RoomModel room, bool isOwner, bool isMember) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum Kartı
          _buildStatusCard(room),
          const SizedBox(height: 16),

          // Açıklama
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Açıklama',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  room.description,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tarih ve Saat Bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Tarih',
                  value: DateFormat('dd MMM yyyy', 'tr').format(room.eventDate),
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'Saat',
                  value: room.eventTime,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  icon: Icons.timelapse,
                  label: 'Süre',
                  value: '${room.durationMinutes ~/ 60} sa',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Katıl/Ayrıl Butonu
          if (!isOwner)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: room.isExpired || !room.isActive
                    ? null
                    : () => _handleJoinLeave(room, isMember),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMember ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isMember ? 'Odadan Ayrıl' : 'Odaya Katıl',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(RoomModel room) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (room.isExpired) {
      statusColor = Colors.grey;
      statusText = 'Etkinlik Sona Erdi';
      statusIcon = Icons.event_busy;
    } else if (room.isOngoing) {
      statusColor = Colors.green;
      statusText = 'Etkinlik Devam Ediyor';
      statusIcon = Icons.play_circle;
    } else if (!room.isActive) {
      statusColor = Colors.orange;
      statusText = 'Oda Kapatıldı';
      statusIcon = Icons.lock;
    } else {
      statusColor = Colors.blue;
      final timeUntil = room.timeUntilStart;
      if (timeUntil.inDays > 0) {
        statusText = '${timeUntil.inDays} gün sonra başlayacak';
      } else if (timeUntil.inHours > 0) {
        statusText = '${timeUntil.inHours} saat sonra başlayacak';
      } else if (timeUntil.inMinutes > 0) {
        statusText = '${timeUntil.inMinutes} dakika sonra başlayacak';
      } else {
        statusText = 'Birazdan başlayacak';
      }
      statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${room.participants.length}/${room.maxParticipants} katılımcı',
                  style: TextStyle(color: statusColor.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _handleJoinLeave(RoomModel room, bool isMember) async {
    if (isMember) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Odadan Ayrıl'),
          content: const Text('Bu odadan ayrılmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ayrıl'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _roomService.leaveRoom(widget.roomId);
      }
    } else {
      if (room.isFull) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oda dolu!'), backgroundColor: Colors.red),
        );
        return;
      }
      await _roomService.joinRoom(widget.roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Odaya katıldın! 🎉'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _handleMenuAction(String action, RoomModel room) async {
    if (action == 'close') {
      await _roomService.closeRoom(widget.roomId);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Odayı Sil'),
          content: const Text('Bu oda kalıcı olarak silinecek. Emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _roomService.deleteRoom(widget.roomId);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'sports': return Colors.green;
      case 'music': return Colors.purple;
      case 'gaming': return Colors.blue;
      case 'study': return Colors.orange;
      case 'chat': return Colors.teal;
      case 'movie': return Colors.red;
      case 'food': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'sports': return Icons.sports_soccer;
      case 'music': return Icons.music_note;
      case 'gaming': return Icons.gamepad;
      case 'study': return Icons.school;
      case 'chat': return Icons.chat;
      case 'movie': return Icons.movie;
      case 'food': return Icons.restaurant;
      default: return Icons.group;
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}