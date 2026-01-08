import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';

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
  
  double _passwordStrength = 0.0;
  String _passwordStrengthKey = '';
  Color _passwordStrengthColor = AppTheme.error;

  void _checkPasswordStrength(String password) {
    double strength = 0.0;
    String strengthKey = '';
    Color strengthColor = AppTheme.error;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthKey = '';
        _passwordStrengthColor = AppTheme.error;
      });
      return;
    }

    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.05;

    if (strength <= 0.4) {
      strengthKey = 'weak';
      strengthColor = AppTheme.error;
    } else if (strength <= 0.6) {
      strengthKey = 'medium';
      strengthColor = AppTheme.warning;
    } else if (strength <= 0.8) {
      strengthKey = 'good';
      strengthColor = Colors.amber;
    } else {
      strengthKey = 'strong';
      strengthColor = AppTheme.success;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthKey = strengthKey;
      _passwordStrengthColor = strengthColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return Column(
      children: [
        // Şifre Field
        TextFormField(
          controller: widget.passwordController,
          obscureText: !_isPasswordVisible,
          enabled: widget.enabled,
          onChanged: _checkPasswordStrength,
          style: TextStyle(color: AppTheme.textPrimary(context)),
          decoration: InputDecoration(
            labelText: locale.get('password'),
            labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textTertiary(context)),
            helperText: locale.get('passwordHelper'),
            helperStyle: TextStyle(color: AppTheme.textTertiary(context)),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textTertiary(context),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: AppTheme.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return locale.get('passwordRequired');
            }
            if (value.length < 6) {
              return locale.get('passwordMinChars');
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
                        backgroundColor: AppTheme.border(context),
                        valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    locale.get(_passwordStrengthKey),
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
                _getPasswordTips(locale),
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textTertiary(context),
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
          style: TextStyle(color: AppTheme.textPrimary(context)),
          decoration: InputDecoration(
            labelText: locale.get('confirmPassword'),
            labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textTertiary(context)),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textTertiary(context),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: AppTheme.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return locale.get('confirmPasswordRequired');
            }
            if (value != widget.passwordController.text) {
              return locale.get('passwordsNotMatch');
            }
            return null;
          },
        ),
      ],
    );
  }
  
  String _getPasswordTips(LocaleProvider locale) {
    final password = widget.passwordController.text;
    List<String> tips = [];
    
    if (password.length < 8) tips.add(locale.get('chars8plus'));
    if (!password.contains(RegExp(r'[A-Z]'))) tips.add(locale.get('uppercase'));
    if (!password.contains(RegExp(r'[0-9]'))) tips.add(locale.get('number'));
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) tips.add(locale.get('specialChar'));
    
    if (tips.isEmpty) return locale.get('strongPassword');
    return '${locale.get('addForStronger')} ${tips.join(', ')}';
  }
}