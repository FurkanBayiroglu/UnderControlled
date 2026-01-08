import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          widget.controller.phoneNumber ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        
        Text(
          'numarasına gönderilen 6 haneli kodu girin',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
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
                : const Text(
                    'Doğrula ve Kayıt Ol',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kod gelmedi mi? ',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (widget.controller.canResend)
              TextButton(
                onPressed: widget.controller.resendCode,
                child: const Text('Tekrar Gönder'),
              )
            else
              Text(
                '${widget.controller.remainingTime} saniye bekleyin',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        
        TextButton(
          onPressed: widget.controller.isLoading 
              ? null 
              : () => widget.controller.reset(),
          child: const Text('Bilgileri Düzenle'),
        ),
        
        if (widget.controller.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.controller.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}