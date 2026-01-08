import 'package:flutter/material.dart';

class ForgotPasswordHeader extends StatelessWidget {
  const ForgotPasswordHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            size: 48,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 24),
        
        // Başlık
        const Text(
          'Şifre Sıfırlama',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Açıklama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'E-posta adresinizi girin. Size şifre sıfırlama bağlantısı göndereceğiz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}