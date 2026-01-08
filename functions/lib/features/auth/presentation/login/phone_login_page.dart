import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/login_controller.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telefon ile Giriş'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Consumer<LoginController>(
          builder: (context, controller, _) {
            if (controller.loginState == LoginState.codeSent ||
                controller.loginState == LoginState.verifying) {
              return _buildSmsVerificationUI(context, controller);
            }
            
            return _buildPhoneInputUI(context, controller);
          },
        ),
      ),
    );
  }
  
  Widget _buildPhoneInputUI(BuildContext context, LoginController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: 48,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Telefon ile Giriş',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Kayıtlı telefon numaranızı girin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !controller.isLoading,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '5XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  prefixText: '+90 ',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası gerekli';
                  }
                  if (!value.startsWith('5')) {
                    return 'Telefon numarası 5 ile başlamalı';
                  }
                  if (value.length != 10) {
                    return 'Telefon numarası 10 haneli olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Send SMS Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await controller.sendPhoneVerification(
                              _phoneController.text,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'SMS Kodu Gönder',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              // Error Message
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSmsVerificationUI(BuildContext context, LoginController controller) {
    final List<TextEditingController> codeControllers = List.generate(
      6,
      (_) => TextEditingController(),
    );
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.message,
                size: 48,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'SMS Kodunu Girin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              controller.phoneNumber ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Code Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextFormField(
                    controller: codeControllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    enabled: !controller.isLoading,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                      if (index == 5 && value.length == 1) {
                        // Son hane girildi, doğrulama yap
                        final code = codeControllers
                            .map((c) => c.text)
                            .join();
                        if (code.length == 6) {
                          controller.verifyPhoneCode(code);
                        }
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Verify Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () {
                        final code = codeControllers
                            .map((c) => c.text)
                            .join();
                        if (code.length == 6) {
                          controller.verifyPhoneCode(code);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Doğrula',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Resend Code
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kod gelmedi mi? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (controller.canResend)
                  TextButton(
                    onPressed: controller.resendCode,
                    child: const Text('Tekrar Gönder'),
                  )
                else
                  Text(
                    '${controller.remainingTime} saniye bekleyin',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            
            // Error Message
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}