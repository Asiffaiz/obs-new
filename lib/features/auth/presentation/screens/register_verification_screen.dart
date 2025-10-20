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

class RegisterVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> registrationData;

  const RegisterVerificationScreen({
    super.key,
    required this.email,
    required this.registrationData,
  });

  @override
  State<RegisterVerificationScreen> createState() =>
      _RegisterVerificationScreenState();
}

class _RegisterVerificationScreenState
    extends State<RegisterVerificationScreen> {
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

    context.read<AuthBloc>().add(
      SendVerifyRegisterCodeRequested(email: widget.email),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    _timer = null;

    // Immediately update the state with new timer values
    setState(() {
      _timeLeft = 60; // Reset to 60 seconds
      _isExpired = false;

      // Clear all code fields when starting a new timer
      for (var controller in _codeControllers) {
        controller.clear();
      }
    });

    // Force a rebuild to ensure the UI shows the updated timer value
    Future.microtask(() {
      if (mounted) {
        setState(() {}); // Force rebuild with updated _timeLeft
      }
    });

    // Create a new timer after the state has been updated
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _isExpired = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
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
          pincodeFor: 'registration',
        ),
      );
    }
  }

  void _resendCode() {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
      _isExpired = false; // Reset expired state immediately on resend
      _timeLeft = 60; // Immediately update the time display
    });

    context.read<AuthBloc>().add(
      // ResendVerificationCodeRequested(email: widget.email),
      SendVerifyRegisterResendCodeRequested(email: widget.email),
    );
  }

  String _formatTime(int seconds) {
    // For a 60-second timer, just show the seconds
    return seconds.toString();
  }

  void _signUp() {
    // Dispatch the registration event
    if (widget.registrationData != null) {
      context.read<AuthBloc>().add(
        RegisterWithApiRequested(userData: widget.registrationData),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.registerPinVerified) {
          _signUp();
        } else if (state.status == AuthStatus.hasMandatoryAgreements) {
          context.go(AppRoutes.unsignedAgreements);
        } else if (state.status == AuthStatus.authenticated ||
            state.status == AuthStatus.apiAuthenticated) {
          // print('authenticated');
          context.go(AppRoutes.home);
          // print('authenticated');
        } else if (state.status == AuthStatus.registerCodeResent) {
          // For resend code success
          setState(() {
            _isResending = false;
            // _isExpired = false; // Ensure expired state is reset
            // _timeLeft = 60; // Explicitly set the time to 60 seconds
            //   _successMessage = 'Verification code resent successfully';
          });

          // Call _startTimer() outside of setState to ensure proper timer initialization
          // Use a small delay to ensure the UI updates first
          Future.delayed(Duration.zero, () {
            if (mounted) {
              _startTimer();
            }
          });
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _errorMessage = 'Something went wrong please try again later';
            _isResending = false; // Ensure resend loader is stopped on error
          });
        }

        setState(() {
          _isLoading = state.status == AuthStatus.loading;
          // Ensure resending state is reset if we're no longer in a loading state
          if (state.status != AuthStatus.loading &&
              state.status != AuthStatus.registerCodeResent) {
            _isResending = false;
          }
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.codeSentText} ',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Flexible(
                          child: Text(
                            widget.email,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
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
                                : (_timeLeft > 0
                                    ? 'Code expires in: ${_formatTime(_timeLeft)} seconds'
                                    : 'Code expires in: 60 seconds'),
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
