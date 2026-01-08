import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  String _selectedCategory = 'chat';
  int _maxParticipants = 10;
  bool _isPrivate = false;
  bool _isCreating = false;
  
  final List<CategoryOption> _categories = [
    CategoryOption(id: 'sports', name: 'Spor', icon: Icons.sports_soccer, color: Colors.green, emoji: '⚽', group: 'Spor & Fitness'),
    CategoryOption(id: 'fitness', name: 'Fitness', icon: Icons.fitness_center, color: Colors.orange, emoji: '💪', group: 'Spor & Fitness'),
    CategoryOption(id: 'yoga', name: 'Yoga & Meditasyon', icon: Icons.self_improvement, color: Colors.teal, emoji: '🧘', group: 'Spor & Fitness'),
    CategoryOption(id: 'dance', name: 'Dans', icon: Icons.nightlife, color: Colors.deepPurple, emoji: '💃', group: 'Spor & Fitness'),
    CategoryOption(id: 'outdoor', name: 'Outdoor & Doğa', icon: Icons.terrain, color: Colors.green, emoji: '🏕️', group: 'Spor & Fitness'),
    CategoryOption(id: 'gaming', name: 'Video Oyunları', icon: Icons.gamepad, color: Colors.blue, emoji: '🎮', group: 'Oyun & Eğlence'),
    CategoryOption(id: 'board_games', name: 'Masa Oyunları', icon: Icons.casino, color: Colors.brown, emoji: '🎲', group: 'Oyun & Eğlence'),
    CategoryOption(id: 'esports', name: 'E-Spor & Turnuva', icon: Icons.emoji_events, color: Colors.red, emoji: '🏆', group: 'Oyun & Eğlence'),
    CategoryOption(id: 'music', name: 'Müzik', icon: Icons.music_note, color: Colors.purple, emoji: '🎵', group: 'Müzik & Sanat'),
    CategoryOption(id: 'art', name: 'Sanat & Çizim', icon: Icons.palette, color: Colors.pink, emoji: '🎨', group: 'Müzik & Sanat'),
    CategoryOption(id: 'photography', name: 'Fotoğrafçılık', icon: Icons.camera_alt, color: Colors.blueGrey, emoji: '📷', group: 'Müzik & Sanat'),
    CategoryOption(id: 'study', name: 'Ders Çalışma', icon: Icons.school, color: Colors.indigo, emoji: '📚', group: 'Eğitim & Gelişim'),
    CategoryOption(id: 'language', name: 'Dil Öğrenme', icon: Icons.translate, color: Colors.cyan, emoji: '🌍', group: 'Eğitim & Gelişim'),
    CategoryOption(id: 'coding', name: 'Kodlama & Yazılım', icon: Icons.code, color: Colors.green, emoji: '💻', group: 'Eğitim & Gelişim'),
    CategoryOption(id: 'reading', name: 'Kitap Kulübü', icon: Icons.menu_book, color: Colors.brown, emoji: '📖', group: 'Eğitim & Gelişim'),
    CategoryOption(id: 'chat', name: 'Genel Sohbet', icon: Icons.chat_bubble, color: Colors.teal, emoji: '💬', group: 'Sosyal'),
    CategoryOption(id: 'debate', name: 'Tartışma & Fikir', icon: Icons.forum, color: Colors.deepOrange, emoji: '🗣️', group: 'Sosyal'),
    CategoryOption(id: 'networking', name: 'Networking', icon: Icons.people, color: Colors.blue, emoji: '🤝', group: 'Sosyal'),
    CategoryOption(id: 'coffee', name: 'Kahve Sohbeti', icon: Icons.coffee, color: Colors.brown, emoji: '☕', group: 'Sosyal'),
    CategoryOption(id: 'movie', name: 'Film & Dizi', icon: Icons.movie, color: Colors.red, emoji: '🎬', group: 'Film & Medya'),
    CategoryOption(id: 'anime', name: 'Anime & Manga', icon: Icons.auto_awesome, color: Colors.pink, emoji: '🌸', group: 'Film & Medya'),
    CategoryOption(id: 'podcast', name: 'Podcast', icon: Icons.podcasts, color: Colors.purple, emoji: '🎙️', group: 'Film & Medya'),
    CategoryOption(id: 'food', name: 'Yemek & Lezzet', icon: Icons.restaurant, color: Colors.amber, emoji: '🍕', group: 'Yemek'),
    CategoryOption(id: 'cooking', name: 'Yemek Yapma', icon: Icons.soup_kitchen, color: Colors.orange, emoji: '👨‍🍳', group: 'Yemek'),
    CategoryOption(id: 'travel', name: 'Seyahat', icon: Icons.flight, color: Colors.lightBlue, emoji: '✈️', group: 'Seyahat'),
    CategoryOption(id: 'tech', name: 'Teknoloji', icon: Icons.computer, color: Colors.blueGrey, emoji: '🖥️', group: 'Teknoloji'),
    CategoryOption(id: 'crypto', name: 'Kripto & Finans', icon: Icons.currency_bitcoin, color: Colors.amber, emoji: '💰', group: 'Teknoloji'),
    CategoryOption(id: 'pets', name: 'Evcil Hayvanlar', icon: Icons.pets, color: Colors.orange, emoji: '🐾', group: 'Diğer'),
    CategoryOption(id: 'cars', name: 'Otomobil', icon: Icons.directions_car, color: Colors.red, emoji: '🚗', group: 'Diğer'),
    CategoryOption(id: 'fashion', name: 'Moda & Stil', icon: Icons.checkroom, color: Colors.pink, emoji: '👗', group: 'Diğer'),
  ];

  CategoryOption get _selectedCategoryOption {
    return _categories.firstWhere((c) => c.id == _selectedCategory, orElse: () => _categories.first);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Yeni Oda Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPreviewCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Oda Bilgileri', Icons.info_outline),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildSectionTitle('Kategori Seç', Icons.category),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('Oda Ayarları', Icons.settings),
            const SizedBox(height: 12),
            _buildParticipantSlider(),
            const SizedBox(height: 16),
            _buildPrivacySwitch(),
            const SizedBox(height: 32),
            _buildCreateButton(),
            const SizedBox(height: 16),
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
        gradient: LinearGradient(colors: [cat.color.withOpacity(0.8), cat.color], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cat.color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                child: Icon(cat.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty ? 'Oda Adı' : _nameController.text,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('${cat.emoji} ${cat.name}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          if (_descriptionController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_descriptionController.text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPreviewBadge(Icons.people, '$_maxParticipants kişi'),
              const SizedBox(width: 12),
              _buildPreviewBadge(_isPrivate ? Icons.lock : Icons.lock_open, _isPrivate ? 'Gizli' : 'Açık'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Odanın adını gir...',
          prefixIcon: Icon(Icons.edit, color: Colors.grey.shade500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Oda adı gerekli';
          if (value.trim().length < 3) return 'En az 3 karakter olmalı';
          return null;
        },
        onChanged: (_) => setState(() {}),
        maxLength: 50,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          hintText: 'Oda hakkında kısa bir açıklama (isteğe bağlı)',
          prefixIcon: Icon(Icons.description, color: Colors.grey.shade500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        maxLines: 2,
        maxLength: 150,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final groups = <String, List<CategoryOption>>{};
    for (var cat in _categories) {
      groups.putIfAbsent(cat.group, () => []).add(cat);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Text(entry.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((cat) {
                  final isSelected = _selectedCategory == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color.withOpacity(0.15) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? cat.color : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(cat.name, style: TextStyle(color: isSelected ? cat.color : Colors.grey.shade700, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                          if (isSelected) ...[const SizedBox(width: 4), Icon(Icons.check_circle, size: 16, color: cat.color)],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParticipantSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              const Text('Maksimum Katılımcı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _selectedCategoryOption.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$_maxParticipants kişi', style: TextStyle(color: _selectedCategoryOption.color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _selectedCategoryOption.color,
              inactiveTrackColor: _selectedCategoryOption.color.withOpacity(0.2),
              thumbColor: _selectedCategoryOption.color,
              overlayColor: _selectedCategoryOption.color.withOpacity(0.2),
            ),
            child: Slider(value: _maxParticipants.toDouble(), min: 2, max: 50, divisions: 48, onChanged: (value) => setState(() => _maxParticipants = value.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text('50', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [5, 10, 20, 30, 50].map((value) {
              final isSelected = _maxParticipants == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _maxParticipants = value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedCategoryOption.color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$value', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _isPrivate ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_isPrivate ? Icons.lock : Icons.lock_open, color: _isPrivate ? Colors.orange : Colors.green, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isPrivate ? 'Gizli Oda' : 'Açık Oda', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_isPrivate ? 'Sadece davet edilenler katılabilir' : 'Herkes odayı görebilir ve katılabilir', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(value: _isPrivate, onChanged: (value) => setState(() => _isPrivate = value), activeColor: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final cat = _selectedCategoryOption;
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: cat.color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isCreating
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, size: 22),
                  SizedBox(width: 10),
                  Text('Odayı Oluştur', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isCreating = true);
    
    try {
      await FirebaseFirestore.instance.collection('rooms').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'createdBy': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [_currentUserId],
        'participantCount': 1,
        'maxParticipants': _maxParticipants,
        'isActive': true,
        'isPrivate': _isPrivate,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('${_nameController.text} odası oluşturuldu! 🎉', style: const TextStyle(fontWeight: FontWeight.w500)))]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

class CategoryOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;
  final String group;

  const CategoryOption({required this.id, required this.name, required this.icon, required this.color, required this.emoji, required this.group});
}