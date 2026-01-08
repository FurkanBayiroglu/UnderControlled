import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';

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
    final locale = context.watch<LocaleProvider>();
    
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      enabled: enabled,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: locale.get('name'),
        labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textTertiary(context)),
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
          return locale.get('nameRequired');
        }
        if (value.trim().length < 2) {
          return locale.get('nameTooShort');
        }
        if (value.trim().length > 50) {
          return locale.get('nameTooLong');
        }
        if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(value.trim())) {
          return locale.get('nameOnlyLetters');
        }
        return null;
      },
    );
  }
}