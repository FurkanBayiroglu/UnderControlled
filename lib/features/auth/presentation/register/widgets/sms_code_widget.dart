import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../controllers/new_register_controller.dart';

class SmsCodeWidget extends StatefulWidget {
  final NewRegisterController controller;
  
  const SmsCodeWidget({
    super.key,
    required this.controller,
  });

  @override
  State<SmsCodeWidget> createState() => _SmsCodeWidgetState();
}

class _SmsCodeWidgetState extends State<SmsCodeWidget> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      widget.controller.verifyCode(code);
    }
  }
  
  void _onCodeChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
      if (index == 5) {
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.message,
            size: 48,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          locale.get('enterSmsCode'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          widget.controller.phoneNumber ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        
        Text(
          locale.get('codeSentTo'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                enabled: !widget.controller.isLoading,
                cursorColor: AppTheme.primary,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.isDark(context) ? Colors.white : AppTheme.lightTextPrimary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                onChanged: (value) => _onCodeChanged(value, index),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: widget.controller.isLoading 
                ? null 
                : () => _verifyCode(),
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
                : Text(
                    locale.get('verifyAndRegister'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locale.get('codeNotReceived'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            if (widget.controller.canResend)
              TextButton(
                onPressed: () {
                  for (var c in _controllers) {
                    c.clear();
                  }
                  _focusNodes[0].requestFocus();
                  widget.controller.resendCode();
                },
                child: Text(locale.get('resend')),
              )
            else
              Text(
                '${widget.controller.remainingTime} ${locale.get('waitSeconds')}',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        
        TextButton(
          onPressed: widget.controller.isLoading 
              ? null 
              : () {
                  for (var c in _controllers) {
                    c.clear();
                  }
                  widget.controller.reset();
                },
          child: Text(locale.get('changeInfo')),
        ),
        
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
    );
  }
}
