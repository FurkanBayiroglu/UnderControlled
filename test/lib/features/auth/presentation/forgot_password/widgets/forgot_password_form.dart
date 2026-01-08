import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/forgot_password_controller.dart';
import '../../../../shared/widgets/loading_button.dart';


class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    print('📧 Form submit edildi: ${_emailController.text}');
    
    final controller = context.read<ForgotPasswordController>();
    await controller.sendPasswordResetEmail(_emailController.text);
    
    if (!mounted) return;
    
    print('📧 İşlem tamamlandı. Başarılı: ${controller.isSuccess}');
    
    if (controller.isSuccess) {
      print('✅ Başarılı dialog gösteriliyor');
      _showSuccessDialog();
    } else if (controller.errorMessage != null) {
      print('❌ Hata mesajı gösteriliyor: ${controller.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  void _showSuccessDialog() {
  // Controller'ı dialog açılmadan önce al
  final email = _emailController.text;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {  // farklı context adı kullan
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.mark_email_read,
          color: Colors.green,
          size: 64,
        ),
        title: const Text(
          'E-posta Gönderildi!',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$email adresine şifre sıfırlama bağlantısı gönderildi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lütfen e-postanızı kontrol edin ve bağlantıya tıklayarak yeni şifrenizi belirleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _handleSubmit();  // Tekrar gönder
            },
            child: const Text('Tekrar Gönder'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();  // Dialog'u kapat
              Navigator.of(context).pop();  // Sayfadan çık
            },
            child: const Text('Giriş Sayfasına Dön'),
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    // Consumer widget kullanarak Provider'a erişim
    return Consumer<ForgotPasswordController>(
      builder: (context, controller, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  labelText: 'E-posta Adresi',
                  hintText: 'ornek@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
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
                validator: controller.validateEmail,
              ),
              const SizedBox(height: 24),
              
              // Gönder Butonu
              LoadingButton(
                onPressed: controller.isLoading ? null : _handleSubmit,
                isLoading: controller.isLoading,
                text: 'Sıfırlama E-postası Gönder',
                icon: Icons.send,
                height: 50,
              ),
              const SizedBox(height: 16),
              
              // Geri Dön
              TextButton.icon(
                onPressed: controller.isLoading
                    ? null
                    : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Giriş Sayfasına Dön'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              
              // Hata mesajı
              if (controller.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Hata: ${controller.errorMessage}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}