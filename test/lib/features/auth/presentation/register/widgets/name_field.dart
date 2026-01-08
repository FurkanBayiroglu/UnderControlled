import 'package:flutter/material.dart';

class NameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  
  const NameField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: 'Ad Soyad',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'İsim gerekli';
        }
        if (value.trim().length < 2) {
          return 'İsim çok kısa';
        }
        if (value.trim().length > 50) {
          return 'İsim çok uzun';
        }
        // Sadece harf ve boşluk kontrolü
        if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(value.trim())) {
          return 'İsim sadece harf içerebilir';
        }
        return null;
      },
    );
  }
}