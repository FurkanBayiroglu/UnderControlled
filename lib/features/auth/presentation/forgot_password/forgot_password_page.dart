import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/forgot_password_controller.dart';
import 'widgets/forgot_password_form.dart';
import 'widgets/forgot_password_header.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider'ı EN ÜSTTE tanımlıyoruz
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordController(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Şifremi Unuttum'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ForgotPasswordHeader(),
                  const SizedBox(height: 32),
                  ForgotPasswordForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}