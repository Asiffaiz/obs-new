import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_bloc.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_event.dart';
import 'package:voicealerts_obs/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:voicealerts_obs/features/auth/presentation/widgets/scan_with_bussiness_card_signin.dart';

import '../../../../config/routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/responsive_padding.dart';
import '../../../../core/widgets/password_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/social_auth_buttons.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      context.read<AuthBloc>().add(
        LoginWithApiRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final logoSize =
        screenSize.width * 0.35 > 160 ? 160.0 : screenSize.width * 0.35;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRoutes.home);
        } else if (state.status == AuthStatus.apiAuthenticated) {
          setState(() {
            _successMessage = "Login successful. Redirecting to dashboard...";
            _isLoading = false;
          });

          // Navigate to dashboard after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            context.go(AppRoutes.home);
          });
        } else if (state.status == AuthStatus.hasMandatoryAgreements) {
          context.go(AppRoutes.unsignedAgreements);
        } else if (state.status ==
            AuthStatus.googleSigninUserNotExistFromGoogleSignIn) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          /////////////
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      SignUpScreen(additionalData: state.additionalData),
            ),
          );
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _errorMessage = 'Something went wrong please try again later';
            _isLoading = false;
          });
        } else if (state.status == AuthStatus.loading) {
          setState(() {
            _isLoading = true;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ResponsivePadding(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 48 : 24,
                  horizontal: isTablet ? 48 : 0.0,
                ),
                constraints: BoxConstraints(
                  minHeight:
                      screenSize.height -
                      (MediaQuery.of(context).padding.top +
                          MediaQuery.of(context).padding.bottom),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   AppStrings.signIn,
                      //   style: Theme.of(context).textTheme.displayLarge,
                      // ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   AppStrings.authLoginJourneyText,
                      //   style: Theme.of(
                      //     context,
                      //   ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                      // ),
                      const SizedBox(height: 4),

                      // Logo
                      Center(
                        child: SizedBox(
                          width: logoSize * 2,
                          height: logoSize,
                          child: Image.asset(
                            'assets/images/logo1.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),
                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_successMessage != null) const SizedBox(height: 16),

                      Text(
                        "Email",
                        style: TextStyle(
                          fontFamily: 'montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.welcomeMenuTextColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: AppStrings.email,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(
                              12.0,
                            ), // adjust for better alignment
                            child: SvgPicture.asset(
                              'assets/icons/ic_email.svg', // replace with your SVG path
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.welcomeMenuTextColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      PasswordTextField(
                        svgPath: 'assets/icons/ic_password.svg',
                        label: AppStrings.password,
                        controller: _passwordController,
                        validator: Validators.validatePasswordLogin,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    context.push(AppRoutes.forgotPassword);
                                  },
                          child: const Text(AppStrings.forgotPassword),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
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
                                  : const Text('Login'),
                        ),
                      ),
                      if (isTablet)
                        const SizedBox(height: 8)
                      else
                        const SizedBox(height: 16),

                      // Don't have an account section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(AppStrings.dontHaveAccount),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      context.push(AppRoutes.signUp);
                                    },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Register here',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Social auth buttons
                      const SocialAuthButtons(),

                      //      const SizedBox(height: 16),

                      // Business Card Scan button
                      //    ScanWithBusinessCardSignin(),
                      const SizedBox(height: 16),
                    ],
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
