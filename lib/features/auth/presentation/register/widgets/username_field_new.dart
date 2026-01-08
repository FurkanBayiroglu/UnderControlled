import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../controllers/new_register_controller.dart';

class UsernameFieldNew extends StatelessWidget {
  final TextEditingController controller;
  final NewRegisterController registerController;
  final bool enabled;
  
  const UsernameFieldNew({
    super.key,
    required this.controller,
    required this.registerController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return TextEditingValue(
            text: newValue.text.toLowerCase(),
            selection: newValue.selection,
          );
        }),
      ],
      decoration: InputDecoration(
        labelText: locale.get('username'),
        labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
        prefixIcon: Icon(Icons.alternate_email, color: AppTheme.textTertiary(context)),
        prefixText: '@',
        prefixStyle: TextStyle(color: AppTheme.textPrimary(context)),
        helperText: locale.get('usernameHelper'),
        helperStyle: TextStyle(color: AppTheme.textTertiary(context)),
        errorText: registerController.usernameError,
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
        suffixIcon: _buildSuffixIcon(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return locale.get('usernameRequired');
        }
        if (value.length < 3) {
          return locale.get('usernameMinChars');
        }
        if (value.length > 20) {
          return locale.get('usernameMaxChars');
        }
        return null;
      },
    );
  }
  
  Widget? _buildSuffixIcon() {
    if (registerController.isCheckingUsername) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (registerController.isUsernameAvailable && controller.text.isNotEmpty) {
      return const Icon(Icons.check_circle, color: AppTheme.success);
    }
    
    if (registerController.usernameError != null && controller.text.isNotEmpty) {
      return const Icon(Icons.error, color: AppTheme.error);
    }
    
    return null;
  }
}