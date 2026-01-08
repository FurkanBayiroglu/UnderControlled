import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return TextFormField(
      controller: controller,
      enabled: enabled,
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
        labelText: 'Kullanıcı Adı',
        prefixIcon: const Icon(Icons.alternate_email),
        prefixText: '@',
        helperText: '3-20 karakter, benzersiz olmalı',
        errorText: registerController.usernameError,
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
        suffixIcon: _buildSuffixIcon(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kullanıcı adı gerekli';
        }
        if (value.length < 3) {
          return 'En az 3 karakter olmalı';
        }
        if (value.length > 20) {
          return 'En fazla 20 karakter olabilir';
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
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (registerController.isUsernameAvailable && controller.text.isNotEmpty) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (registerController.usernameError != null && controller.text.isNotEmpty) {
      return const Icon(Icons.error, color: Colors.red);
    }
    
    return null;
  }
}