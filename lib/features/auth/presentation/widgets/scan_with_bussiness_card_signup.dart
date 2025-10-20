import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/config/routes.dart';

class ScanWithBusinessCardSignup extends StatelessWidget {
  const ScanWithBusinessCardSignup({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        context.push(AppRoutes.scan);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/business-cards.png',
            height: 24,
            width: 24,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.credit_card,
                size: 24,
                color: Colors.blue,
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Sign up with Business Card',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
