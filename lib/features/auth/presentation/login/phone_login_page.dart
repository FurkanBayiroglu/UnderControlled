import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import 'controllers/login_controller.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  // SMS kod alanları için controller ve focus node'lar
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  
  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        backgroundColor: AppTheme.background(context),
        appBar: AppBar(
          title: Text('Telefon ile Giriş', style: TextStyle(color: AppTheme.textPrimary(context))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textPrimary(context)),
        ),
        body: Consumer<LoginController>(
          builder: (context, controller, _) {
            // Giriş başarılı - AuthWrapper'a yönlendir
            if (controller.loginState == LoginState.completed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              });
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Giriş yapılıyor...',
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              );
            }
            
            if (controller.loginState == LoginState.codeSent ||
                controller.loginState == LoginState.verifying) {
              // SMS ekranına geçildiğinde ilk alana fokusla
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_codeControllers[0].text.isEmpty && _focusNodes[0].canRequestFocus) {
                  _focusNodes[0].requestFocus();
                }
              });
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Telefon ile Giriş',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Kayıtlı telefon numaranızı girin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 32),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !controller.isLoading,
                style: TextStyle(color: AppTheme.textPrimary(context)),
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
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
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              
              // Error Message
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSmsVerificationUI(BuildContext context, LoginController controller) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            // Header
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.message,
                  size: 48,
                  color: AppTheme.success,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'SMS Kodunu Girin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              controller.phoneNumber ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
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
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    enabled: !controller.isLoading,
                    cursorColor: AppTheme.primary,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.isDark(context) ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppTheme.surface(context),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      
                      // Son hane girildi, doğrulama yap
                      if (index == 5 && value.length == 1) {
                        final code = _codeControllers
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
                        final code = _codeControllers
                            .map((c) => c.text)
                            .join();
                        if (code.length == 6) {
                          controller.verifyPhoneCode(code);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                if (controller.canResend)
                  TextButton(
                    onPressed: () {
                      // Kod alanlarını temizle
                      for (var c in _codeControllers) {
                        c.clear();
                      }
                      _focusNodes[0].requestFocus();
                      controller.resendCode();
                    },
                    child: const Text('Tekrar Gönder'),
                  )
                else
                  Text(
                    '${controller.remainingTime} saniye bekleyin',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            
            // Back Button
            TextButton(
              onPressed: controller.isLoading
                  ? null
                  : () {
                      // Kod alanlarını temizle
                      for (var c in _codeControllers) {
                        c.clear();
                      }
                      controller.reset();
                    },
              child: const Text('Numarayı Değiştir'),
            ),
            
            // Error Message
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
