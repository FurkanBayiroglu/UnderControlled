import 'package:flutter/material.dart';

class EmailFieldNew extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  
  const EmailFieldNew({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: 'E-posta',
        prefixIcon: const Icon(Icons.email_outlined),
        helperText: 'Giriş yapmak için kullanacağınız e-posta',
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
          return 'E-posta gerekli';
        }
        
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Geçerli bir e-posta adresi girin';
        }
        
        return null;
      },
    );
  }
}