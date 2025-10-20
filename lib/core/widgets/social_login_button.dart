import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String iconPath;
  final String text;
  final bool isApple;

  const SocialLoginButton({
    super.key,
    required this.onPressed,
    required this.iconPath,
    required this.text,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isApple ? Colors.white : Colors.black87,
        backgroundColor: isApple ? Colors.black : Colors.white,
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: isApple ? Colors.black : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, height: 24, width: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isApple ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
