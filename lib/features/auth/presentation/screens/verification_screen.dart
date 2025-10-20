import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../../config/routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_padding.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  bool _isExpired = false;

  // Timer for PIN expiration (60 seconds)
  int _timeLeft = 60;
  Timer? _timer;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 60; // Reset to 60 seconds
      _isExpired = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isCodeComplete {
    return _codeControllers.every((controller) => controller.text.isNotEmpty);
  }

  void _verifyCode() {
    if (_isCodeComplete) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });

      // Get the complete 4-digit code
      final pincode =
          _codeControllers.map((controller) => controller.text).join();

      context.read<AuthBloc>().add(
        VerifyCodeRequested(
          email: widget.email,
          code: pincode,
          pincodeFor: 'forget_password',
        ),
      );
    }
  }

  void _resendCode() {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    context.read<AuthBloc>().add(
      ResendVerificationCodeRequested(email: widget.email),
    );
  }

  String _formatTime(int seconds) {
    // For a 60-second timer, just show the seconds
    return seconds.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.pinVerified) {
          // For verification code success
          // Navigate to reset password screen with email and code
          final pincode =
              _codeControllers.map((controller) => controller.text).join();
          context.push(
            AppRoutes.resetPassword,
            extra: {'email': widget.email, 'code': pincode},
          );
        } else if (state.status == AuthStatus.forgotPasswordCodeResent) {
          // For resend code success
          setState(() {
            _isResending = false;
            _successMessage = 'Verification code resent successfully';
            _startTimer(); // Restart timer after resending
          });
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _errorMessage = state.errorMessage ?? 'An error occurred';
            _isResending = false;
          });
        }

        setState(() {
          _isLoading = state.status == AuthStatus.loading;
        });
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Verification')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the 4-digit verification code sent to your email to reset your password.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
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
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Success message
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Text(
                          '${AppStrings.codeSentText} ',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          widget.email,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Countdown Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isExpired
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: _isExpired ? Colors.red : Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isExpired
                                ? 'Code expired'
                                : 'Code expires in: ${_formatTime(_timeLeft)} seconds',
                            style: TextStyle(
                              color: _isExpired ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildVerificationCodeFields(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading || !_isCodeComplete || _isExpired)
                                ? null
                                : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appButtonColor,
                          disabledBackgroundColor: Colors.grey.shade300,
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
                                : Text(
                                  _isExpired
                                      ? 'Code Expired'
                                      : AppStrings.continueText,
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpired
                              ? "Code expired. "
                              : "Didn't receive code? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed:
                              (_isLoading ||
                                      _isResending ||
                                      (!_isExpired && _timeLeft > 0))
                                  ? null
                                  : _resendCode,
                          child:
                              _isResending
                                  ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _isExpired
                                        ? "Resend Now"
                                        : (_timeLeft > 0
                                            ? "Wait ${_formatTime(_timeLeft)}s"
                                            : "Resend Now"),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCodeFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        4,
        (index) => SizedBox(
          width: 60,
          height: 60,
          child: TextField(
            controller: _codeControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              counterText: '',
              filled: _isExpired,
              fillColor: _isExpired ? Colors.grey.shade200 : null,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            enabled: !_isExpired,
            onChanged: (value) {
              if (value.isNotEmpty && index < 3) {
                _focusNodes[index + 1].requestFocus();
              }
              if (_isCodeComplete) {
                FocusScope.of(context).unfocus();
              }
              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
