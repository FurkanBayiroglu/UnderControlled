import 'package:flutter/material.dart';

class RegisterHeaderNew extends StatelessWidget {
  const RegisterHeaderNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon veya Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.purple.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_outlined,
            size: 48,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 24),
        
        // Başlık
        const Text(
          'Hesap Oluştur',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Alt başlık
        Text(
          'UnderControlled\'a katılın',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        
        // Bilgi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user,
                size: 16,
                color: Colors.green,
              ),
              SizedBox(width: 4),
              Text(
                'SMS doğrulamalı güvenli kayıt',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}