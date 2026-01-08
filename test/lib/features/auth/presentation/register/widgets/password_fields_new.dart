import 'package:flutter/material.dart';

class PasswordFieldsNew extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool enabled;
  
  const PasswordFieldsNew({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    this.enabled = true,
  });

  @override
  State<PasswordFieldsNew> createState() => _PasswordFieldsNewState();
}

class _PasswordFieldsNewState extends State<PasswordFieldsNew> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Şifre güç göstergesi
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.red;

  void _checkPasswordStrength(String password) {
    double strength = 0.0;
    String strengthText = '';
    Color strengthColor = Colors.red;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.red;
      });
      return;
    }

    // Uzunluk kontrolü
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    
    // Küçük harf kontrolü
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    
    // Büyük harf kontrolü
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    
    // Sayı kontrolü
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    
    // Özel karakter kontrolü
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.05;

    // Güç seviyesi belirleme
    if (strength <= 0.4) {
      strengthText = 'Zayıf';
      strengthColor = Colors.red;
    } else if (strength <= 0.6) {
      strengthText = 'Orta';
      strengthColor = Colors.orange;
    } else if (strength <= 0.8) {
      strengthText = 'İyi';
      strengthColor = Colors.amber;
    } else {
      strengthText = 'Güçlü';
      strengthColor = Colors.green;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Şifre Field
        TextFormField(
          controller: widget.passwordController,
          obscureText: !_isPasswordVisible,
          enabled: widget.enabled,
          onChanged: _checkPasswordStrength,
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_outline),
            helperText: 'En az 6 karakter',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
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
            if (value == null || value.isEmpty) {
              return 'Şifre gerekli';
            }
            if (value.length < 6) {
              return 'Şifre en az 6 karakter olmalı';
            }
            return null;
          },
        ),
        
        // Şifre güç göstergesi
        if (widget.passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _passwordStrengthText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _passwordStrengthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getPasswordTips(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Şifre Tekrar Field
        TextFormField(
          controller: widget.confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: 'Şifre Tekrar',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
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
            if (value == null || value.isEmpty) {
              return 'Şifre tekrarı gerekli';
            }
            if (value != widget.passwordController.text) {
              return 'Şifreler eşleşmiyor';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  String _getPasswordTips() {
    final password = widget.passwordController.text;
    List<String> tips = [];
    
    if (password.length < 8) {
      tips.add('8+ karakter');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      tips.add('büyük harf');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      tips.add('rakam');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      tips.add('özel karakter');
    }
    
    if (tips.isEmpty) {
      return 'Güçlü şifre! ✓';
    }
    
    return 'Daha güçlü için ekleyin: ${tips.join(', ')}';
  }
}