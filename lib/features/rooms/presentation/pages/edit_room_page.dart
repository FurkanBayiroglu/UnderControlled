import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';

class EditRoomPage extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;

  const EditRoomPage({
    super.key,
    required this.roomId,
    required this.roomData,
  });

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  
  late String _selectedCategory;
  late int _maxParticipants;
  late bool _isPrivate;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _durationMinutes;
  bool _isSaving = false;
  
  final List<CategoryOption> _categories = [
    CategoryOption(id: 'sports', name: 'Spor', icon: Icons.sports_soccer, color: const Color(0xFF10B981), emoji: '⚽'),
    CategoryOption(id: 'fitness', name: 'Fitness', icon: Icons.fitness_center, color: const Color(0xFFF97316), emoji: '💪'),
    CategoryOption(id: 'yoga', name: 'Yoga', icon: Icons.self_improvement, color: const Color(0xFF14B8A6), emoji: '🧘'),
    CategoryOption(id: 'gaming', name: 'Oyun', icon: Icons.gamepad, color: const Color(0xFF3B82F6), emoji: '🎮'),
    CategoryOption(id: 'music', name: 'Müzik', icon: Icons.music_note, color: const Color(0xFFA855F7), emoji: '🎵'),
    CategoryOption(id: 'art', name: 'Sanat', icon: Icons.palette, color: const Color(0xFFEC4899), emoji: '🎨'),
    CategoryOption(id: 'study', name: 'Ders', icon: Icons.school, color: const Color(0xFF6366F1), emoji: '📚'),
    CategoryOption(id: 'coding', name: 'Kodlama', icon: Icons.code, color: const Color(0xFF10B981), emoji: '💻'),
    CategoryOption(id: 'chat', name: 'Sohbet', icon: Icons.chat_bubble, color: const Color(0xFF14B8A6), emoji: '💬'),
    CategoryOption(id: 'movie', name: 'Film', icon: Icons.movie, color: const Color(0xFFDC2626), emoji: '🎬'),
    CategoryOption(id: 'food', name: 'Yemek', icon: Icons.restaurant, color: const Color(0xFFF59E0B), emoji: '🍕'),
    CategoryOption(id: 'travel', name: 'Seyahat', icon: Icons.flight, color: const Color(0xFF0EA5E9), emoji: '✈️'),
    CategoryOption(id: 'tech', name: 'Teknoloji', icon: Icons.computer, color: const Color(0xFF475569), emoji: '🖥️'),
    CategoryOption(id: 'coffee', name: 'Kahve', icon: Icons.coffee, color: const Color(0xFF78350F), emoji: '☕'),
  ];

  CategoryOption get _selectedCategoryOption {
    return _categories.firstWhere((c) => c.id == _selectedCategory, orElse: () => _categories.first);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final room = widget.roomData;
    _nameController = TextEditingController(text: room['name'] ?? '');
    _descriptionController = TextEditingController(text: room['description'] ?? '');
    _selectedCategory = room['category'] ?? 'chat';
    _maxParticipants = room['maxParticipants'] ?? 10;
    _isPrivate = room['isPrivate'] ?? false;
    _durationMinutes = room['durationMinutes'] ?? 120;
    
    final eventDate = room['eventDate'] as Timestamp?;
    _selectedDate = eventDate?.toDate() ?? DateTime.now().add(const Duration(days: 1));
    
    final eventTime = room['eventTime'] as String? ?? '19:00';
    final timeParts = eventTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 19,
      minute: timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate() async {
    final isDark = AppTheme.isDark(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: _selectedCategoryOption.color, surface: const Color(0xFF1E1E1E))
                : ColorScheme.light(primary: _selectedCategoryOption.color),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final isDark = AppTheme.isDark(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: _selectedCategoryOption.color, surface: const Color(0xFF1E1E1E))
                : ColorScheme.light(primary: _selectedCategoryOption.color),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text('Odayı Düzenle', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPreviewCard(),
            const SizedBox(height: 24),
            _buildSection('Oda Bilgileri', Icons.info_outline),
            const SizedBox(height: 12),
            _buildTextField(_nameController, 'Oda adı', Icons.edit, validator: true),
            const SizedBox(height: 12),
            _buildTextField(_descriptionController, 'Açıklama (opsiyonel)', Icons.description, maxLines: 3),
            const SizedBox(height: 24),
            _buildSection('Tarih ve Saat', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildDateTimeRow(isDark),
            const SizedBox(height: 12),
            _buildDurationSelector(isDark),
            const SizedBox(height: 24),
            _buildSection('Kategori', Icons.category),
            const SizedBox(height: 12),
            _buildCategorySelector(isDark),
            const SizedBox(height: 24),
            _buildSection('Ayarlar', Icons.settings),
            const SizedBox(height: 12),
            _buildParticipantSlider(isDark),
            const SizedBox(height: 12),
            _buildPrivacySwitch(isDark),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final cat = _selectedCategoryOption;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cat.color.withOpacity(0.8), cat.color]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(cat.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _nameController.text.isEmpty ? 'Oda Adı' : _nameController.text,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(Icons.calendar_today, _formatDate(_selectedDate)),
              _badge(Icons.access_time, '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              _badge(Icons.people, '$_maxParticipants kişi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _selectedCategoryOption.color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool validator = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textTertiary(context)),
          prefixIcon: Icon(icon, color: _selectedCategoryOption.color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator ? (v) => v == null || v.trim().isEmpty ? 'Bu alan gerekli' : null : null,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildDateTimeRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildDateTimeTile(Icons.calendar_today, 'Tarih', _formatDate(_selectedDate), _selectDate, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildDateTimeTile(Icons.access_time, 'Saat', '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', _selectTime, isDark)),
      ],
    );
  }

  Widget _buildDateTimeTile(IconData icon, String label, String value, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _selectedCategoryOption.color, size: 18),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector(bool isDark) {
    final durations = [60, 120, 180, 240];
    final labels = ['1 Sa', '2 Sa', '3 Sa', '4 Sa'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Süre', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 12),
          Row(
            children: List.generate(durations.length, (i) {
              final isSelected = _durationMinutes == durations[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _durationMinutes = durations[i]),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedCategoryOption.color : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.id),
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : AppTheme.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? cat.color : AppTheme.border(context)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(cat.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary(context)), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticipantSlider(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppTheme.textSecondary(context), size: 20),
              const SizedBox(width: 8),
              Text('Katılımcı: ', style: TextStyle(color: AppTheme.textPrimary(context))),
              Text('$_maxParticipants kişi', style: TextStyle(color: _selectedCategoryOption.color, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _maxParticipants.toDouble(),
            min: 2,
            max: 50,
            divisions: 48,
            activeColor: _selectedCategoryOption.color,
            inactiveColor: _selectedCategoryOption.color.withOpacity(0.2),
            onChanged: (v) => setState(() => _maxParticipants = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Icon(_isPrivate ? Icons.lock : Icons.lock_open, color: _isPrivate ? Colors.orange : Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isPrivate ? 'Gizli Oda' : 'Açık Oda', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                Text(_isPrivate ? 'Sadece davetliler' : 'Herkes katılabilir', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Switch(value: _isPrivate, onChanged: (v) => setState(() => _isPrivate = v), activeColor: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedCategoryOption.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  const SizedBox(width: 10),
                  Text('Kaydet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    try {
      final eventDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'maxParticipants': _maxParticipants,
        'isPrivate': _isPrivate,
        'eventDate': Timestamp.fromDate(eventDateTime),
        'eventTime': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'durationMinutes': _durationMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Oda güncellendi! ✓'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class CategoryOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  const CategoryOption({required this.id, required this.name, required this.icon, required this.color, required this.emoji});
}
