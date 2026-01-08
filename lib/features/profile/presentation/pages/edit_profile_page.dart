import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/premium/premium_service.dart';
import '../../../premium/presentation/pages/premium_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _usernameController.text = data['username'] ?? '';
      _bioController.text = data['bio'] ?? '';
      setState(() {
        _photoUrl = data['photoUrl'];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final premiumService = context.watch<PremiumService>();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        title: Text(locale.get('editProfile'), style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(locale.get('save'), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profil fotoğrafı
              _buildPhotoSection(locale, premiumService),
              const SizedBox(height: 32),

              // Form alanları
              _buildTextField(
                controller: _nameController,
                label: locale.get('name'),
                icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locale.isTurkish ? 'İsim gerekli' : 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _usernameController,
                label: locale.get('searchHint').split(' ').first, // "Kullanıcı adı"
                icon: Icons.alternate_email_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locale.isTurkish ? 'Kullanıcı adı gerekli' : 'Username is required';
                  }
                  if (value.length < 3) {
                    return locale.isTurkish ? 'En az 3 karakter' : 'At least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _bioController,
                label: locale.isTurkish ? 'Hakkında' : 'Bio',
                icon: Icons.info_outline_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Premium banner (eğer premium değilse)
              if (!premiumService.isPremium)
                _buildPremiumBanner(locale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(LocaleProvider locale, PremiumService premiumService) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(locale, premiumService),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: premiumService.isPremium 
                      ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                      : AppTheme.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.surface(context),
                  backgroundImage: _photoUrl != null && !_isUploadingPhoto ? NetworkImage(_photoUrl!) : null,
                  child: _isUploadingPhoto
                      ? const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3)
                      : _photoUrl == null
                          ? Icon(Icons.person_rounded, size: 60, color: AppTheme.textTertiary(context))
                          : null,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(locale, premiumService),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isUploadingPhoto ? AppTheme.textTertiary(context) : AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface(context), width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          locale.get('changePhoto'),
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
        ),
        if (!premiumService.isPremium) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond_rounded, size: 14, color: AppTheme.warning),
                const SizedBox(width: 4),
                Text(
                  locale.get('premiumRequired'),
                  style: const TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showPhotoOptions(LocaleProvider locale, PremiumService premiumService) {
    // Premium değilse premium sayfasına yönlendir
    if (!premiumService.isPremium) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: const Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.diamond_rounded, size: 48, color: AppTheme.warning),
              ),
              const SizedBox(height: 16),
              Text(
                locale.get('premiumRequired'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locale.get('profilePhotoRequiresPremium'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
                  },
                  child: Text(locale.get('goPremium')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      return;
    }

    // Premium ise - Fotoğraf seçenekleri
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: const Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locale.get('changePhoto'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 24),
            
            // Galeriden seç
            _buildPhotoOption(
              icon: Icons.photo_library_rounded,
              label: locale.isTurkish ? 'Galeriden Seç' : 'Choose from Gallery',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            
            // Kameradan çek
            _buildPhotoOption(
              icon: Icons.camera_alt_rounded,
              label: locale.isTurkish ? 'Kameradan Çek' : 'Take Photo',
              color: AppTheme.info,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            
            // Fotoğrafı kaldır (varsa)
            if (_photoUrl != null) ...[
              const SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.delete_rounded,
                label: locale.get('removePhoto'),
                color: AppTheme.error,
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(locale);
                },
              ),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Firebase Storage'a yükle
      final ref = _storage.ref().child('profile_photos').child('$userId.jpg');
      final uploadTask = ref.putFile(
        File(pickedFile.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'u güncelle
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _photoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        final locale = context.read<LocaleProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.get('photoUpdated')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        String errorMessage;
        final errorStr = e.toString();
        final locale = context.read<LocaleProvider>();
        
        if (errorStr.contains('object-not-found')) {
          errorMessage = locale.isTurkish 
              ? 'Dosya bulunamadı (zaten silinmiş olabilir)'
              : 'File not found (may already be deleted)';
        } else if (errorStr.contains('unauthorized') || errorStr.contains('permission')) {
          errorMessage = locale.isTurkish
              ? 'Yetkilendirme hatası. Storage rules kontrol edin.'
              : 'Authorization error. Check Storage rules.';
        } else if (errorStr.contains('bucket')) {
          errorMessage = locale.isTurkish
              ? 'Firebase Storage aktif değil. Firebase Console\'dan aktif edin.'
              : 'Firebase Storage not enabled. Enable it from Firebase Console.';
        } else {
          errorMessage = locale.isTurkish ? 'Hata: $e' : 'Error: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(LocaleProvider locale) async {
    try {
      setState(() => _isUploadingPhoto = true);

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Storage'dan sil (hata olursa görmezden gel - dosya yoksa sorun değil)
      try {
        final ref = _storage.ref().child('profile_photos').child('$userId.jpg');
        await ref.delete();
      } catch (e) {
        // object-not-found hatası normal, dosya zaten yok demek
        debugPrint('Storage silme: $e (önemsiz)');
      }

      // Firestore'u güncelle
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _photoUrl = null;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.get('photoRemoved')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      // Firestore hatası olsa bile fotoğrafı kaldır gibi davran
      setState(() => _photoUrl = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.get('photoRemoved')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
        prefixIcon: Icon(icon, color: AppTheme.textTertiary(context)),
        filled: true,
        fillColor: AppTheme.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(LocaleProvider locale) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.get('goPremium'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale.get('premiumSubtitle'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final locale = context.read<LocaleProvider>();
    setState(() => _isLoading = true);

    try {
      // TEST MODU: Fotoğraf yükleme devre dışı
      // Sadece isim, kullanıcı adı ve bio güncelle
      
      await _firestore.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
      });

      // Auth displayName güncelle
      await _auth.currentUser?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locale.get('profileUpdated')), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${locale.get('error')}: $e'), backgroundColor: AppTheme.error),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}
