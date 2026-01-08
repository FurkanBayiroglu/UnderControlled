import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../controllers/new_register_controller.dart';
import 'register_header_new.dart';
import 'name_field.dart';
import 'username_field_new.dart';
import 'email_field_new.dart';
import 'phone_field.dart';
import 'password_fields_new.dart';

class RegisterFormWidget extends StatefulWidget {
  final NewRegisterController controller;
  
  const RegisterFormWidget({
    super.key,
    required this.controller,
  });

  @override
  State<RegisterFormWidget> createState() => _RegisterFormWidgetState();
}

class _RegisterFormWidgetState extends State<RegisterFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      widget.controller.checkUsername(_usernameController.text);
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _handleSubmit() {
    final locale = context.read<LocaleProvider>();
    
    if (!_formKey.currentState!.validate()) return;
    
    if (widget.controller.usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.get('chooseValidUsername')),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    
    widget.controller.submitFormAndSendCode(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phoneNumber: _phoneController.text,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const RegisterHeaderNew(),
          const SizedBox(height: 32),
          
          // Ad Soyad
          NameField(
            controller: _nameController,
            enabled: !widget.controller.isLoading,
          ),
          const SizedBox(height: 16),
          
          // Kullanıcı Adı
          UsernameFieldNew(
            controller: _usernameController,
            registerController: widget.controller,
            enabled: !widget.controller.isLoading,
          ),
          const SizedBox(height: 16),
          
          // E-posta
          EmailFieldNew(
            controller: _emailController,
            enabled: !widget.controller.isLoading,
          ),
          const SizedBox(height: 16),
          
          // Telefon Numarası
          PhoneField(
            controller: _phoneController,
            enabled: !widget.controller.isLoading,
            validator: widget.controller.validatePhoneNumber,
          ),
          const SizedBox(height: 16),
          
          // Şifre Alanları
          PasswordFieldsNew(
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            enabled: !widget.controller.isLoading,
          ),
          const SizedBox(height: 32),
          
          // Kayıt Ol Butonu
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: widget.controller.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.controller.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_android),
                        const SizedBox(width: 8),
                        Text(
                          locale.get('sendSmsCode'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Giriş yap linki
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locale.get('alreadyHaveAccount'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(locale.get('login')),
              ),
            ],
          ),
          
          // Hata mesajı
          if (widget.controller.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.controller.errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}