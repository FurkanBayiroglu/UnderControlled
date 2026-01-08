import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../main.dart';
import 'controllers/new_register_controller.dart';
import 'widgets/register_form_widget.dart';
import 'widgets/sms_code_widget.dart';

class NewRegisterPage extends StatelessWidget {
  const NewRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return ChangeNotifierProvider(
      create: (_) => NewRegisterController(),
      child: Scaffold(
        backgroundColor: AppTheme.background(context),
        appBar: AppBar(
          title: Text(locale.get('register'), style: TextStyle(color: AppTheme.textPrimary(context))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textPrimary(context)),
        ),
        body: Consumer<NewRegisterController>(
          builder: (context, controller, _) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildContent(context, controller, locale),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, NewRegisterController controller, LocaleProvider locale) {
    switch (controller.state) {
      case RegisterState.initial:
      case RegisterState.dataEntered:
      case RegisterState.sendingCode:
        return RegisterFormWidget(controller: controller);
      
      case RegisterState.codeSent:
      case RegisterState.verifying:
        return SmsCodeWidget(controller: controller);
      
      case RegisterState.completed:
        // AuthWrapper'a yönlendir
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.get('registerSuccess')),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        });
        return Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
              const SizedBox(height: 16),
              Text(
                locale.get('registerSuccess'),
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              const CircularProgressIndicator(color: AppTheme.primary),
            ],
          ),
        );
      
      case RegisterState.error:
        return Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? locale.get('error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(locale.get('tryAgain')),
            ),
          ],
        );
      
      default:
        return const CircularProgressIndicator(color: AppTheme.primary);
    }
  }
}