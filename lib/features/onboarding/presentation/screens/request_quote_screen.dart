import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/core/constants/strings.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/form_label.dart';

import '../../../../config/routes.dart';

class RequestQuoteScreen extends StatelessWidget {
  const RequestQuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Quote'),
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => context.go(AppRoutes.welcomeMenu),
        // ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 48 : 24,
            horizontal: isTablet ? 100 : 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get a customized quote for your business',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fill in the details below and our team will get back to you with a personalized quote.',
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
              // Email field
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
              const SizedBox(height: 16),
              // Company field
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
              // Requirements field
              formLabel("Requirements"),

              SizedBox(height: 10),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us what you need...',
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
                      const SnackBar(
                        content: Text('Quote request submitted successfully!'),
                      ),
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
                    'Request Quote',
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
