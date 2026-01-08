import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../rooms/presentation/pages/room_detail_page.dart';
import '../../../rooms/presentation/pages/create_room_page.dart';
import '../../../rooms/presentation/pages/edit_room_page.dart';

class RoomListPage extends StatefulWidget {
  final bool showBackButton;
  final int initialTab;
  
  const RoomListPage({super.key, this.showBackButton = true, this.initialTab = 0});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedCategory = 'all';
  bool _isCategoryLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isInitialLoading = false);
    });
  }

  List<Map<String, dynamic>> _getCategories(LocaleProvider locale) => [
    {'id': 'all', 'name': locale.get('allCategories'), 'emoji': '🌟'},
    {'id': 'sports', 'name': locale.get('catSports'), 'emoji': '⚽'},
    {'id': 'gaming', 'name': locale.get('catGaming'), 'emoji': '🎮'},
    {'id': 'music', 'name': locale.get('catMusic'), 'emoji': '🎵'},
    {'id': 'study', 'name': locale.get('catStudy'), 'emoji': '📚'},
    {'id': 'chat', 'name': locale.get('catChat'), 'emoji': '💬'},
    {'id': 'movie', 'name': locale.get('catMovie'), 'emoji': '🎬'},
    {'id': 'food', 'name': locale.get('catFood'), 'emoji': '🍕'},
    {'id': 'tech', 'name': locale.get('catTech'), 'emoji': '💻'},
    {'id': 'travel', 'name': locale.get('catTravel'), 'emoji': '✈️'},
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = AppTheme.isDark(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // TabBar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary(context),
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(icon: const Icon(Icons.explore_rounded, size: 22), text: locale.get('explore')),
                Tab(icon: const Icon(Icons.groups_rounded, size: 22), text: locale.get('joined')),
                Tab(icon: const Icon(Icons.add_circle_outline_rounded, size: 22), text: locale.get('createdRooms')),
              ],
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController, 
                children: [
                  _buildExploreTab(locale, isDark),
                  _buildJoinedTab(locale),
                  _buildCreatedTab(locale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab(LocaleProvider locale, bool isDark) {
    final categories = _getCategories(locale);
    
    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.only(top: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat['id'];
              return GestureDetector(
                onTap: () {
                  if (_selectedCategory != cat['id']) {
                    setState(() {
                      _selectedCategory = cat['id'];
                      _isCategoryLoading = true;
                    });
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _isCategoryLoading = false);
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border(context)),
                  ),
                  child: Row(
                    children: [
                      Text(cat['emoji'], style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(cat['name'], style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: (_isCategoryLoading || _isInitialLoading)
              ? _buildShimmerLoading()
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').orderBy('createdAt', descending: true).limit(100).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return _buildShimmerLoading();
              if (snapshot.hasError) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textTertiary(context)),
                  const SizedBox(height: 16),
                  Text(locale.get('roomsCouldNotLoad'), style: TextStyle(color: AppTheme.textSecondary(context))),
                  const SizedBox(height: 8),
                  TextButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded), label: Text(locale.get('tryAgain'))),
                ]));
              }
              
              final allRooms = snapshot.data?.docs ?? [];
              final availableRooms = allRooms.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final participants = List<String>.from(data['participants'] ?? []);
                final isActive = data['isActive'] ?? true;
                final category = data['category'] ?? 'chat';
                if (!isActive) return false;
                if (participants.contains(_currentUserId)) return false;
                if (_selectedCategory != 'all' && category != _selectedCategory) return false;
                return true;
              }).toList();
              
              if (availableRooms.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.explore_outlined,
                  message: _selectedCategory == 'all' ? locale.get('noRoomsToJoin') : locale.get('noRoomsInCategory'),
                  actionLabel: locale.get('createRoom'),
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomPage())),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableRooms.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  final doc = availableRooms[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _ExploreRoomCard(roomId: doc.id, roomData: data, onTap: () => _navigateToRoom(doc.id), onJoin: () => _joinRoom(doc.id, data));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJoinedTab(LocaleProvider locale) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').where('participants', arrayContains: _currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        final rooms = snapshot.data?.docs ?? [];
        if (rooms.isEmpty) return _buildEmptyState(icon: Icons.groups_outlined, message: locale.get('noJoinedGroups'), actionLabel: locale.get('explore'), onAction: () => _tabController.animateTo(0));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final doc = rooms[index];
            final data = doc.data() as Map<String, dynamic>;
            final isCreator = data['createdBy'] == _currentUserId;
            return _RoomCard(roomId: doc.id, roomData: data, isCreator: isCreator, showEditButton: false, onTap: () => _navigateToRoom(doc.id), onLeaveTap: isCreator ? null : () => _leaveRoom(doc.id));
          },
        );
      },
    );
  }

  Widget _buildCreatedTab(LocaleProvider locale) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').where('createdBy', isEqualTo: _currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        final rooms = snapshot.data?.docs ?? [];
        if (rooms.isEmpty) return _buildEmptyState(icon: Icons.add_circle_outline_rounded, message: locale.get('noCreatedRooms'), actionLabel: locale.get('createRoom'), onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomPage())));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final doc = rooms[index];
            final data = doc.data() as Map<String, dynamic>;
            return _RoomCard(roomId: doc.id, roomData: data, isCreator: true, showEditButton: true, onTap: () => _navigateToRoom(doc.id), onEditTap: () => _navigateToEdit(doc.id, data), onDeleteTap: () => _showDeleteDialog(doc.id, data['name'] ?? ''));
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() => ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 5, itemBuilder: (context, index) => _ShimmerCard(index: index));

  Widget _buildEmptyState({required IconData icon, required String message, String? actionLabel, VoidCallback? onAction}) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 48, color: AppTheme.primary)),
      const SizedBox(height: 20),
      Text(message, style: TextStyle(fontSize: 16, color: AppTheme.textSecondary(context)), textAlign: TextAlign.center),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ],
    ]));
  }

  void _navigateToRoom(String roomId) => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailPage(roomId: roomId)));
  void _navigateToEdit(String roomId, Map<String, dynamic> data) => Navigator.push(context, MaterialPageRoute(builder: (_) => EditRoomPage(roomId: roomId, roomData: data)));

  Future<void> _joinRoom(String roomId, Map<String, dynamic> data) async {
    try {
      final maxParticipants = data['maxParticipants'] ?? 50;
      final currentParticipants = List<String>.from(data['participants'] ?? []);
      final locale = context.read<LocaleProvider>();
      if (currentParticipants.length >= maxParticipants) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.get('roomFull')), backgroundColor: AppTheme.error));
        return;
      }
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'participants': FieldValue.arrayUnion([_currentUserId]), 'participantCount': FieldValue.increment(1)});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('joinedGroup')} 🎉'), backgroundColor: AppTheme.success));
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.read<LocaleProvider>().get('error')}: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _leaveRoom(String roomId) async {
    final locale = context.read<LocaleProvider>();
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surface(context),
      title: Text(locale.get('leaveRoom'), style: TextStyle(color: AppTheme.textPrimary(context))),
      content: Text(locale.get('leaveRoomConfirm'), style: TextStyle(color: AppTheme.textSecondary(context))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.get('cancel'), style: TextStyle(color: AppTheme.textSecondary(context)))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: Text(locale.get('leave'))),
      ],
    ));
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'participants': FieldValue.arrayRemove([_currentUserId]), 'participantCount': FieldValue.increment(-1)});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.get('leftGroup')), backgroundColor: AppTheme.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('error')}: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _showDeleteDialog(String roomId, String roomName) async {
    final locale = context.read<LocaleProvider>();
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surface(context),
      title: Text(locale.get('deleteRoom'), style: TextStyle(color: AppTheme.textPrimary(context))),
      content: Text(locale.get('deleteConfirm'), style: TextStyle(color: AppTheme.textSecondary(context))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.get('cancel'), style: TextStyle(color: AppTheme.textSecondary(context)))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: Text(locale.get('delete'))),
      ],
    ));
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.get('roomDeleted')), backgroundColor: AppTheme.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${locale.get('error')}: $e'), backgroundColor: AppTheme.error));
      }
    }
  }
}

class _ExploreRoomCard extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> roomData;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _ExploreRoomCard({required this.roomId, required this.roomData, required this.onTap, required this.onJoin});

  static const Map<String, Color> categoryColors = {'sports': Color(0xFF10B981), 'gaming': Color(0xFF3B82F6), 'music': Color(0xFF8B5CF6), 'study': Color(0xFFF59E0B), 'chat': Color(0xFF06B6D4), 'movie': Color(0xFFEF4444), 'food': Color(0xFFF97316), 'tech': Color(0xFF6366F1), 'travel': Color(0xFF0EA5E9)};
  static const Map<String, IconData> categoryIcons = {'sports': Icons.sports_soccer_rounded, 'gaming': Icons.sports_esports_rounded, 'music': Icons.music_note_rounded, 'study': Icons.school_rounded, 'chat': Icons.chat_bubble_rounded, 'movie': Icons.movie_rounded, 'food': Icons.restaurant_rounded, 'tech': Icons.computer_rounded, 'travel': Icons.flight_rounded};

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final category = roomData['category'] ?? 'chat';
    final color = categoryColors[category] ?? AppTheme.primary;
    final icon = categoryIcons[category] ?? Icons.group_rounded;
    final name = roomData['name'] ?? '';
    final description = roomData['description'] ?? '';
    final participants = List<String>.from(roomData['participants'] ?? []);
    final maxParticipants = roomData['maxParticipants'] ?? 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color]), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.people_rounded, size: 14, color: AppTheme.textTertiary(context)),
                  const SizedBox(width: 4),
                  Text('${participants.length}/$maxParticipants', style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
                  if (participants.length >= maxParticipants) ...[
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(locale.get('full'), style: TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.w600))),
                  ],
                ]),
              ])),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: participants.length >= maxParticipants ? null : onJoin, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), child: Text(locale.get('join'), style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> roomData;
  final bool isCreator;
  final bool showEditButton;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onLeaveTap;

  const _RoomCard({required this.roomId, required this.roomData, required this.isCreator, required this.showEditButton, required this.onTap, this.onEditTap, this.onDeleteTap, this.onLeaveTap});

  static const Map<String, Color> categoryColors = {'sports': Color(0xFF10B981), 'gaming': Color(0xFF3B82F6), 'music': Color(0xFF8B5CF6), 'study': Color(0xFFF59E0B), 'chat': Color(0xFF06B6D4), 'movie': Color(0xFFEF4444), 'food': Color(0xFFF97316), 'tech': Color(0xFF6366F1), 'travel': Color(0xFF0EA5E9)};
  static const Map<String, IconData> categoryIcons = {'sports': Icons.sports_soccer_rounded, 'gaming': Icons.sports_esports_rounded, 'music': Icons.music_note_rounded, 'study': Icons.school_rounded, 'chat': Icons.chat_bubble_rounded, 'movie': Icons.movie_rounded, 'food': Icons.restaurant_rounded, 'tech': Icons.computer_rounded, 'travel': Icons.flight_rounded};

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final category = roomData['category'] ?? 'chat';
    final color = categoryColors[category] ?? AppTheme.primary;
    final icon = categoryIcons[category] ?? Icons.group_rounded;
    final name = roomData['name'] ?? '';
    final description = roomData['description'] ?? '';
    final participantCount = (roomData['participants'] as List?)?.length ?? roomData['participantCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color]), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (isCreator) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('Admin', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [Icon(Icons.people_rounded, size: 14, color: AppTheme.textTertiary(context)), const SizedBox(width: 4), Text('$participantCount ${locale.get('people')}', style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12))]),
                ])),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.arrow_forward_rounded, color: color, size: 20)),
              ]),
              if (showEditButton || onLeaveTap != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border(context)))),
                  child: Row(children: [
                    if (showEditButton) ...[
                      Expanded(child: _ActionButton(icon: Icons.edit_rounded, label: locale.get('edit'), color: const Color(0xFF3B82F6), onTap: onEditTap ?? () {})),
                      const SizedBox(width: 8),
                      Expanded(child: _ActionButton(icon: Icons.delete_rounded, label: locale.get('delete'), color: AppTheme.error, onTap: onDeleteTap ?? () {})),
                    ],
                    if (onLeaveTap != null) Expanded(child: _ActionButton(icon: Icons.exit_to_app_rounded, label: locale.get('leave'), color: AppTheme.error, onTap: onLeaveTap!)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))]),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final int index;
  const _ShimmerCard({required this.index});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.addListener(() { if (mounted) setState(() {}); });
    Future.delayed(Duration(milliseconds: widget.index * 100), () { if (mounted) _controller.repeat(reverse: true); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final opacity = _animation.value;
    final baseColor = isDark ? Colors.white.withOpacity(opacity * 0.12) : Colors.grey.withOpacity(opacity * 0.25);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(context))),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(14))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 16, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 8),
          Container(width: 150, height: 12, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 8),
          Row(children: [Container(width: 60, height: 10, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 12), Container(width: 80, height: 10, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)))]),
        ])),
        const SizedBox(width: 12),
        Container(width: 70, height: 36, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(10))),
      ]),
    );
  }
}
