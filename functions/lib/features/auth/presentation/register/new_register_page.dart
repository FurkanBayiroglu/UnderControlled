import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/new_register_controller.dart';
import 'widgets/register_form_widget.dart';
import 'widgets/sms_code_widget.dart';

class NewRegisterPage extends StatelessWidget {
  const NewRegisterPage({super.key}); // const constructor var

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewRegisterController(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Kayıt Ol'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Consumer<NewRegisterController>(
          builder: (context, controller, _) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildContent(context, controller),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, NewRegisterController controller) {
    switch (controller.state) {
      case RegisterState.initial:
      case RegisterState.dataEntered:
      case RegisterState.sendingCode:
        return RegisterFormWidget(controller: controller);
      
      case RegisterState.codeSent:
      case RegisterState.verifying:
        return SmsCodeWidget(controller: controller);
      
      case RegisterState.completed:
        // Ana sayfaya yönlendir
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarılı! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
        return const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Kayıt başarılı!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              CircularProgressIndicator(),
            ],
          ),
        );
      
      case RegisterState.error:
        return Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? 'Bir hata oluştu',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.reset(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        );
      
      default:
        return const CircularProgressIndicator();
    }
  }
}