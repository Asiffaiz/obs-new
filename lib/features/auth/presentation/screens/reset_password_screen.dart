import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/password_text_field.dart';
import '../../../../core/widgets/responsive_padding.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? code;

  const ResetPasswordScreen({super.key, this.email, this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _email;
  String? _code;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _code = widget.code;

    // If email or code is missing, try to get from AuthBloc state
    // if (_email == null || _code == null) {
    //   final authState = context.read<AuthBloc>().state;
    //   if (authState.additionalData != null) {
    //     _email = authState.additionalData!['email'] as String?;
    //     _code = authState.additionalData!['code'] as String?;
    //   }
    // }

    // // If still missing, show error
    // if (_email == null || _code == null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     setState(() {
    //       _errorMessage = 'Missing verification information. Please try again.';
    //     });
    //   });
    // }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_email == null || _code == null) {
        setState(() {
          _errorMessage = 'Missing verification information. Please try again.';
        });
        return;
      }

      context.read<AuthBloc>().add(
        SetNewPasswordRequested(
          newPassword: _newPasswordController.text,
          email: _email!,
          code: _code!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        // Navigate to forgot password screen when back button is pressed
        context.go(AppRoutes.forgotPassword);
        return false; // Prevent default back behavior
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successfully! Please sign in.'),
              ),
            );
            context.go(AppRoutes.signIn);
            setState(() {
              _errorMessage = "";
            });
          } else if (state.status == AuthStatus.error) {
            setState(() {
              _errorMessage = state.errorMessage ?? 'An error occurred';
            });
          }

          setState(() {
            _isLoading = state.status == AuthStatus.loading;
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.forgotPassword),
            ),
            title: const Text(AppStrings.resetPassword),
          ),
          body: SafeArea(
            child: ResponsivePadding(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  constraints: BoxConstraints(
                    minHeight:
                        screenSize.height -
                        (MediaQuery.of(context).padding.top +
                            MediaQuery.of(context).padding.bottom +
                            kToolbarHeight),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.passwordDifferentText,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 32),

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        PasswordTextField(
                          svgPath: 'assets/icons/ic_password.svg',
                          label: AppStrings.newPassword,
                          controller: _newPasswordController,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 16),
                        PasswordTextField(
                          svgPath: 'assets/icons/ic_password.svg',
                          label: AppStrings.confirmPassword,
                          controller: _confirmPasswordController,
                          validator:
                              (value) => Validators.validateConfirmPassword(
                                value,
                                _newPasswordController.text,
                              ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.appButtonColor,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(AppStrings.resetPassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
