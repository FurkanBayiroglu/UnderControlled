import 'package:flutter/material.dart';

enum AuthButtonType { primary, secondary, text }

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AuthButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AuthButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AuthButtonType.primary:
        return _buildPrimaryButton(context);
      case AuthButtonType.secondary:
        return _buildSecondaryButton(context);
      case AuthButtonType.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _buildButtonChild(Colors.white),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildButtonChild(Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: _buildButtonChild(Theme.of(context).primaryColor),
    );
  }

  Widget _buildButtonChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}