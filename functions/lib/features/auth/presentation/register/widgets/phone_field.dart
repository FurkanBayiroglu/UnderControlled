import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  
  const PhoneField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10, // 10 rakam
      enabled: enabled,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Sadece rakam girilsin
        LengthLimitingTextInputFormatter(10), // Max 10 karakter
      ],
      decoration: InputDecoration(
        labelText: 'Telefon Numarası',
        hintText: '5XXXXXXXXX',
        prefixIcon: const Icon(Icons.phone),
        prefixText: '+90 ',
        prefixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        helperText: 'SMS doğrulaması için kullanılacak',
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
        counterText: '', // Karakter sayacını gizle
      ),
      validator: validator ?? _defaultValidator,
    );
  }
  
  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }
    
    // Türkiye telefon numarası kontrolü (10 haneli, 5 ile başlamalı)
    if (!value.startsWith('5')) {
      return 'Telefon numarası 5 ile başlamalı';
    }
    
    if (value.length != 10) {
      return 'Telefon numarası 10 haneli olmalı';
    }
    
    return null;
  }
}