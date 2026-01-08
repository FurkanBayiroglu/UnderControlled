import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../data/models/room_model.dart';
import '../../data/services/room_service.dart';
import '../widgets/room_members.dart';
import '../widgets/room_chat.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';

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

  String _formatDate(DateTime date, LocaleProvider locale) {
    final monthsTr = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final months = locale.isTurkish ? monthsTr : monthsEn;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
    final locale = context.watch<LocaleProvider>();
    
    return StreamBuilder<RoomModel?>(
      stream: _roomService.getRoomStream(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.background(context),
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final room = snapshot.data;
        if (room == null) {
          return Scaffold(
            backgroundColor: AppTheme.background(context),
            appBar: AppBar(
              backgroundColor: AppTheme.surface(context),
              title: Text(locale.get('room'), style: TextStyle(color: AppTheme.textPrimary(context))),
            ),
            body: Center(child: Text(locale.get('roomNotFound'), style: TextStyle(color: AppTheme.textSecondary(context)))),
          );
        }

        final isOwner = room.createdBy == _currentUserId;
        final isMember = room.participants.contains(_currentUserId);
        final categoryColor = _getCategoryColor(room.category);

        return Scaffold(
          backgroundColor: AppTheme.background(context),
          body: SafeArea(
            child: Column(
              children: [
                // Kompakt Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [categoryColor, categoryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // AppBar Row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${room.participants.length}/${room.maxParticipants} ${locale.get('participants').toLowerCase()}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (isOwner)
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                              ),
                              onSelected: (value) => _handleMenuAction(value, room, locale),
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'close', child: Row(children: [const Icon(Icons.close, color: Colors.orange), const SizedBox(width: 8), Text(locale.get('closeRoom'))])),
                                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, color: Colors.red), const SizedBox(width: 8), Text(locale.get('deleteRoom'))])),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Info Row
                      Row(
                        children: [
                          _infoBadge(Icons.calendar_today_rounded, _formatDate(room.eventDate, locale)),
                          const SizedBox(width: 8),
                          _infoBadge(Icons.access_time_rounded, room.eventTime),
                          const SizedBox(width: 8),
                          _infoBadge(Icons.timelapse_rounded, '${room.durationMinutes ~/ 60}${locale.get('hoursShort')}'),
                          const Spacer(),
                          _statusBadge(room, locale),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Katıl/Ayrıl Butonu
                if (!isOwner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: AppTheme.surface(context),
                    child: ElevatedButton(
                      onPressed: room.isExpired || !room.isActive ? null : () => _handleJoinLeave(room, isMember, locale),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember ? AppTheme.error : AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isMember ? locale.get('leaveRoom') : locale.get('joinRoom'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                
                // TabBar
                Container(
                  color: AppTheme.surface(context),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textSecondary(context),
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_rounded, size: 20),
                            const SizedBox(width: 6),
                            Text('${locale.get('participants')} (${room.participants.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_rounded, size: 20),
                            const SizedBox(width: 6),
                            Text(locale.get('chat')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RoomMembers(participants: room.participants, ownerId: room.createdBy),
                      RoomChat(roomId: widget.roomId, isActive: room.isActive && !room.isExpired, isMember: isMember),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statusBadge(RoomModel room, LocaleProvider locale) {
    String text;
    Color bgColor;
    
    if (room.isExpired) {
      text = locale.get('ended');
      bgColor = Colors.grey;
    } else if (room.isOngoing) {
      text = locale.get('ongoing');
      bgColor = AppTheme.success;
    } else if (!room.isActive) {
      text = locale.get('closed');
      bgColor = Colors.orange;
    } else {
      final days = room.timeUntilStart.inDays;
      final hours = room.timeUntilStart.inHours;
      if (days > 0) {
        text = '$days${locale.get('daysShort')}';
      } else if (hours > 0) {
        text = '$hours${locale.get('hoursShort')}';
      } else {
        text = locale.get('soon');
      }
      bgColor = AppTheme.primary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _handleJoinLeave(RoomModel room, bool isMember, LocaleProvider locale) async {
    if (isMember) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface(context),
          title: Text(locale.get('leaveRoom'), style: TextStyle(color: AppTheme.textPrimary(context))),
          content: Text(locale.get('leaveRoomConfirm'), style: TextStyle(color: AppTheme.textSecondary(context))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.get('cancel'), style: TextStyle(color: AppTheme.textSecondary(context)))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: Text(locale.get('leave')),
            ),
          ],
        ),
      );
      if (confirm == true) await _roomService.leaveRoom(widget.roomId);
    } else {
      if (room.isFull) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.get('roomFull')), backgroundColor: AppTheme.error));
        return;
      }
      await _roomService.joinRoom(widget.roomId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('joinedGroup')} 🎉'), backgroundColor: AppTheme.success));
    }
  }

  void _handleMenuAction(String action, RoomModel room, LocaleProvider locale) async {
    if (action == 'close') {
      await _roomService.closeRoom(widget.roomId);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface(context),
          title: Text(locale.get('deleteRoom'), style: TextStyle(color: AppTheme.textPrimary(context))),
          content: Text(locale.get('deleteConfirm'), style: TextStyle(color: AppTheme.textSecondary(context))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.get('cancel'), style: TextStyle(color: AppTheme.textSecondary(context)))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: Text(locale.get('delete')),
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
      case 'sports': return const Color(0xFF10B981);
      case 'music': return const Color(0xFF8B5CF6);
      case 'gaming': return const Color(0xFF3B82F6);
      case 'study': return const Color(0xFFF59E0B);
      case 'chat': return const Color(0xFF06B6D4);
      case 'movie': return const Color(0xFFEF4444);
      case 'food': return const Color(0xFFF97316);
      case 'tech': return const Color(0xFF6366F1);
      case 'travel': return const Color(0xFF14B8A6);
      default: return const Color(0xFF6B7280);
    }
  }
}
