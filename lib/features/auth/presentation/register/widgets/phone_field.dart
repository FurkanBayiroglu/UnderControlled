import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';

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
    final locale = context.watch<LocaleProvider>();
    
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      enabled: enabled,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: locale.get('phone'),
        labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
        hintText: '5XXXXXXXXX',
        hintStyle: TextStyle(color: AppTheme.textTertiary(context)),
        prefixIcon: Icon(Icons.phone, color: AppTheme.textTertiary(context)),
        prefixText: '+90 ',
        prefixStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppTheme.textPrimary(context),
        ),
        helperText: locale.get('phoneHelper'),
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
        counterText: '',
      ),
      validator: validator ?? (value) => _defaultValidator(value, locale),
    );
  }
  
  String? _defaultValidator(String? value, LocaleProvider locale) {
    if (value == null || value.isEmpty) {
      return locale.get('phoneRequired');
    }
    
    if (!value.startsWith('5')) {
      return locale.get('phoneStartWith5');
    }
    
    if (value.length != 10) {
      return locale.get('phoneMustBe10');
    }
    
    return null;
  }
}