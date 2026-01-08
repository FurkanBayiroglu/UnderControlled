class AuthValidators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final email = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    // Yasaklı domain kontrolü (opsiyonel)
    const blockedDomains = ['tempmail.com', 'throwaway.email'];
    final domain = email.split('@').last;
    if (blockedDomains.contains(domain)) {
      return 'Bu e-posta servisi kabul edilmiyor';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    // Güçlü şifre kontrolü (opsiyonel)
    // if (!value.contains(RegExp(r'[A-Z]'))) {
    //   return 'En az bir büyük harf kullanın';
    // }
    // if (!value.contains(RegExp(r'[0-9]'))) {
    //   return 'En az bir rakam kullanın';
    // }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }

    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İsim gerekli';
    }

    final name = value.trim();
    if (name.length < 2) {
      return 'İsim çok kısa';
    }

    if (name.length > 50) {
      return 'İsim çok uzun';
    }

    // Sadece harf ve boşluk kontrolü
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(name)) {
      return 'İsim sadece harf içerebilir';
    }

    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }

    final username = value.toLowerCase();

    if (username.length < 3) {
      return 'En az 3 karakter olmalı';
    }

    if (username.length > 20) {
      return 'En fazla 20 karakter olabilir';
    }

    if (!RegExp(r'^[a-z][a-z0-9._]*$').hasMatch(username)) {
      return 'Harf ile başlamalı, sadece küçük harf, sayı, nokta ve alt çizgi içerebilir';
    }

    if (username.endsWith('.')) {
      return 'Nokta ile bitemez';
    }

    if (username.contains('..') || username.contains('__')) {
      return 'Ardışık nokta veya alt çizgi kullanılamaz';
    }

    // Reserved usernames
    const reserved = [
      'admin', 'root', 'system', 'moderator', 'mod', 'owner',
      'undercontrolled', 'official', 'support', 'help', 'info',
      'test', 'demo', 'user', 'profile', 'settings',
    ];

    if (reserved.contains(username)) {
      return 'Bu kullanıcı adı rezerve edilmiş';
    }

    return null;
  }

  // Phone validation (opsiyonel)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opsiyonel alan
    }

    // Sadece rakam ve bazı karakterler
    final phone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (phone.length < 10) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }

  // Password strength checker
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.none;
    }

    int strength = 0;

    // Length check
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 4) return PasswordStrength.medium;
    if (strength <= 6) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength {
  none,
  weak,
  medium,
  good,
  strong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get text {
    switch (this) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Zayıf';
      case PasswordStrength.medium:
        return 'Orta';
      case PasswordStrength.good:
        return 'İyi';
      case PasswordStrength.strong:
        return 'Güçlü';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.amber;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  double get value {
    switch (this) {
      case PasswordStrength.none:
        return 0.0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

// Material import gerekli
import 'package:flutter/material.dart';