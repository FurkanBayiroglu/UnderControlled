import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/premium/premium_service.dart';
import '../../../../core/premium/premium_model.dart';
import '../../../premium/presentation/pages/premium_page.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'chat';
  int _maxParticipants = 20;
  bool _isPrivate = false;
  bool _isLoading = false;
  bool _canCreate = true;
  int _remainingRooms = 3;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'sports', 'name_tr': 'Spor', 'name_en': 'Sports', 'icon': Icons.sports_soccer_rounded, 'color': Color(0xFF10B981)},
    {'id': 'gaming', 'name_tr': 'Oyun', 'name_en': 'Gaming', 'icon': Icons.sports_esports_rounded, 'color': Color(0xFF3B82F6)},
    {'id': 'music', 'name_tr': 'Müzik', 'name_en': 'Music', 'icon': Icons.music_note_rounded, 'color': Color(0xFF8B5CF6)},
    {'id': 'study', 'name_tr': 'Çalışma', 'name_en': 'Study', 'icon': Icons.school_rounded, 'color': Color(0xFFF59E0B)},
    {'id': 'chat', 'name_tr': 'Sohbet', 'name_en': 'Chat', 'icon': Icons.chat_bubble_rounded, 'color': Color(0xFF06B6D4)},
    {'id': 'movie', 'name_tr': 'Film', 'name_en': 'Movie', 'icon': Icons.movie_rounded, 'color': Color(0xFFEF4444)},
    {'id': 'food', 'name_tr': 'Yemek', 'name_en': 'Food', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFF97316)},
    {'id': 'tech', 'name_tr': 'Teknoloji', 'name_en': 'Tech', 'icon': Icons.computer_rounded, 'color': Color(0xFF6366F1)},
    {'id': 'art', 'name_tr': 'Sanat', 'name_en': 'Art', 'icon': Icons.palette_rounded, 'color': Color(0xFFEC4899)},
  ];

  Color get _selectedColor {
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return category['color'] as Color;
  }

  @override
  void initState() {
    super.initState();
    _checkRoomLimit();
  }

  Future<void> _checkRoomLimit() async {
    final premiumService = context.read<PremiumService>();
    final canCreate = await premiumService.canCreateRoom();
    final remaining = await premiumService.getRemainingRoomSlots();
    
    if (mounted) {
      setState(() {
        _canCreate = canCreate;
        _remainingRooms = remaining;
        // Premium kullanıcılar için max katılımcı sınırını güncelle
        if (premiumService.isPremium) {
          _maxParticipants = 50; // Premium varsayılan
        }
      });
    }
  }

  int get _maxParticipantsLimit {
    final premiumService = context.read<PremiumService>();
    return premiumService.maxParticipants;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final premiumService = context.watch<PremiumService>();

    // Limit kontrolü - oda oluşturulamıyorsa uyarı göster
    if (!_canCreate && !premiumService.isPremium) {
      return _buildLimitReachedScreen(locale);
    }

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          locale.isTurkish ? 'Yeni Oda Oluştur' : 'Create New Room',
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Room Name
            _buildSectionTitle(locale.isTurkish ? 'Oda Adı' : 'Room Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: locale.isTurkish ? 'Örn: Akşam Sohbeti' : 'E.g., Evening Chat',
              icon: Icons.meeting_room_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return locale.isTurkish ? 'Oda adı gerekli' : 'Room name is required';
                }
                if (value.length < 3) {
                  return locale.isTurkish ? 'En az 3 karakter' : 'At least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Description
            _buildSectionTitle(locale.isTurkish ? 'Açıklama' : 'Description'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hint: locale.isTurkish ? 'Odanı tanımlayan kısa bir açıklama...' : 'A short description of your room...',
              icon: Icons.description_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Category Selection
            _buildSectionTitle(locale.isTurkish ? 'Kategori' : 'Category'),
            const SizedBox(height: 12),
            _buildCategoryGrid(locale),

            const SizedBox(height: 24),

            // Max Participants
            _buildSectionTitle(locale.isTurkish ? 'Maksimum Katılımcı' : 'Max Participants'),
            const SizedBox(height: 12),
            _buildParticipantSlider(locale),

            const SizedBox(height: 24),

            // Privacy Toggle
            _buildPrivacyToggle(locale),

            const SizedBox(height: 32),

            // Create Button
            _buildCreateButton(locale),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary(context),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textTertiary(context)),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(LocaleProvider locale) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category['id'];
        final color = category['color'] as Color;

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [color.withOpacity(0.8), color])
                  : null,
              color: isSelected ? null : AppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : AppTheme.border(context),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: isSelected ? Colors.white : AppTheme.textSecondary(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  locale.isTurkish ? category['name_tr'] : category['name_en'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParticipantSlider(LocaleProvider locale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.people_rounded, color: _selectedColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    locale.isTurkish ? 'Kişi Sayısı' : 'People',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_selectedColor.withOpacity(0.8), _selectedColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_maxParticipants',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _selectedColor,
              inactiveTrackColor: _selectedColor.withOpacity(0.2),
              thumbColor: _selectedColor,
              overlayColor: _selectedColor.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _maxParticipants.toDouble(),
              min: 2,
              max: 100,
              divisions: 49,
              onChanged: (value) => setState(() => _maxParticipants = value.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2', style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
              Text('100', style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(LocaleProvider locale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isPrivate ? AppTheme.warning.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
              color: _isPrivate ? AppTheme.warning : AppTheme.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPrivate
                      ? (locale.isTurkish ? 'Özel Oda' : 'Private Room')
                      : (locale.isTurkish ? 'Herkese Açık' : 'Public Room'),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPrivate
                      ? (locale.isTurkish ? 'Sadece davetliler katılabilir' : 'Only invited users can join')
                      : (locale.isTurkish ? 'Herkes katılabilir' : 'Anyone can join'),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            activeColor: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(LocaleProvider locale) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_selectedColor.withOpacity(0.9), _selectedColor]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () => _createRoom(locale),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          locale.isTurkish ? 'Odayı Oluştur' : 'Create Room',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createRoom(LocaleProvider locale) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('rooms').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'maxParticipants': _maxParticipants,
        'isPrivate': _isPrivate,
        'isActive': true,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId],
        'participantCount': 1,
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(locale.isTurkish ? 'Oda oluşturuldu!' : 'Room created!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${locale.isTurkish ? 'Hata' : 'Error'}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildLimitReachedScreen(LocaleProvider locale) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.meeting_room_outlined, size: 64, color: AppTheme.warning),
              ),
              const SizedBox(height: 24),
              Text(
                locale.get('roomLimitReached'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                locale.get('roomLimitMessage'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
                  },
                  icon: const Icon(Icons.diamond_rounded),
                  label: Text(locale.get('goPremium'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(locale.get('cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}