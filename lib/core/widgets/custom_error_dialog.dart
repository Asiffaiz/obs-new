import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';

class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String subMessage;
  final String retryButtonText;
  final String cancelButtonText;
  final VoidCallback onRetry;

  const CustomErrorDialog({
    super.key,
    this.title = 'ERROR!',
    this.message = 'We are unable to continue the process.',
    this.subMessage = 'Please try again to complete the request.',
    this.retryButtonText = 'Try Again',
    this.cancelButtonText = 'Cancel',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Image.asset(
              'assets/icons/ic_error.png',
              width: 80,
              height: 80,
              color: AppColors.primaryColor,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a sad emoji icon if the asset is not found
                return Icon(
                  Icons.sentiment_dissatisfied,
                  color: Colors.red,
                  size: 80,
                );
              },
            ),
            const SizedBox(height: 16),

            // Error title
            // Text(
            //   title,
            //   style: const TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.red,
            //   ),
            //   textAlign: TextAlign.center,
            // ),
            // const SizedBox(height: 16),

            // Error message
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Sub message
            Text(
              subMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Retry button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: Text(retryButtonText),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                cancelButtonText,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    String title = 'ERROR!',
    String message = 'We are unable to continue the process.',
    String subMessage = 'Please try again to complete the request.',
    String retryButtonText = 'Try Again',
    String cancelButtonText = 'Cancel',
    required VoidCallback onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomErrorDialog(
          title: title,
          message: message,
          subMessage: subMessage,
          retryButtonText: retryButtonText,
          cancelButtonText: cancelButtonText,
          onRetry: onRetry,
        );
      },
    );
  }
}
