import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/core/constants/strings.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/form_label.dart';

import '../../../../config/routes.dart';

class BookDemoScreen extends StatelessWidget {
  const BookDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Free Demo'),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => context.go(AppRoutes.welcomeMenu),
        // ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get your free demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fill in your details for your demo session.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              // Name field
              formLabel(AppStrings.fullName),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone field
              formLabel(AppStrings.companyName),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Company Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              formLabel(AppStrings.emailAddress),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Phone field
              formLabel(AppStrings.phoneNumber),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo booking successful!')),
                    );

                    // Navigate to sign in
                    // Future.delayed(const Duration(seconds: 2), () {
                    //   context.go(AppRoutes.signIn);
                    // });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Demo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
