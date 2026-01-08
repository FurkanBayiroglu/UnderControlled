import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';

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
    final locale = context.watch<LocaleProvider>();
    
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enabled: enabled,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: locale.get('email'),
        labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textTertiary(context)),
        helperText: locale.get('emailHelper'),
        helperStyle: TextStyle(color: AppTheme.textTertiary(context)),
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
        if (value == null || value.trim().isEmpty) {
          return locale.get('emailRequired');
        }
        
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        
        if (!emailRegex.hasMatch(value.trim())) {
          return locale.get('emailInvalid');
        }
        
        return null;
      },
    );
  }
}