import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/agreement_model.dart';
import '../bloc/agreements_bloc.dart';
import '../bloc/agreements_event.dart';
import '../bloc/agreements_state.dart';

class SendToSigneeScreen extends StatefulWidget {
  final AgreementModel agreement;
  final VoidCallback? onSuccess;
  final String? comeFrom;

  const SendToSigneeScreen({
    super.key,
    required this.agreement,
    this.onSuccess,
    this.comeFrom,
  });

  @override
  State<SendToSigneeScreen> createState() => _SendToSigneeScreenState();
}

class _SendToSigneeScreenState extends State<SendToSigneeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  // Animation controller for success dialog
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSendToSignee() {
    if (_formKey.currentState!.validate()) {
      context.read<AgreementsBloc>().add(
        SendToSignee(
          agreementId: widget.agreement.id.toString(),
          name: _nameController.text,
          email: _emailController.text,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          message:
              _messageController.text.isEmpty ? null : _messageController.text,
        ),
      );
    }
  }

  void _showSentToSigneeSuccessDialog(BuildContext context) {
    // Reset and start the animation
    _animationController.reset();
    _animationController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Agreement Sent!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'The agreement has been successfully sent to the signee.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close success dialog
                            if (widget.onSuccess != null) {
                              widget.onSuccess!();
                            } else if (widget.comeFrom == 'optional') {
                              context.pop();
                            } else if (widget.comeFrom == 'mandatory') {
                              context.go(AppRoutes.agreements);
                            } else {
                              context.pop(); // Default: go back
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appButtonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Back to Agreements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return BlocListener<AgreementsBloc, AgreementsState>(
      listener: (context, state) {
        if (state.status == AgreementsStatus.sentToSignee) {
          // Show success popup for sent to signee
          _showSentToSigneeSuccessDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.agreement.title),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: isTablet ? 48.0 : 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send Agreement to Signee',
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: 'Full Name ',
                                            style: TextStyle(
                                              fontFamily: 'montserrat',
                                              fontSize: 14,
                                              color:
                                                  AppColors
                                                      .welcomeMenuTextColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: ' *',
                                                style: TextStyle(
                                                  color:
                                                      AppColors
                                                          .welcomeMenuTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Tooltip(
                                          message:
                                              'Full Name is the full name of the signee.',
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.all(10),
                                          triggerMode: TooltipTriggerMode.tap,
                                          showDuration: const Duration(
                                            seconds: 60,
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color:
                                                AppColors.welcomeMenuTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter full name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 16,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Title',
                                          style: TextStyle(
                                            fontFamily: 'montserrat',
                                            fontSize: 14,
                                            color:
                                                AppColors.welcomeMenuTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Tooltip(
                                          message:
                                              'Title is the title of the signee.',
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.all(10),
                                          triggerMode: TooltipTriggerMode.tap,
                                          showDuration: const Duration(
                                            seconds: 60,
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color:
                                                AppColors.welcomeMenuTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _titleController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter title',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 16,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Email Address ',
                                  style: TextStyle(
                                    fontFamily: 'montserrat',
                                    fontSize: 14,
                                    color: AppColors.welcomeMenuTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                        color: AppColors.welcomeMenuTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message:
                                    'Email Address is the email address of the signee.',
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(10),
                                showDuration: const Duration(seconds: 60),
                                triggerMode: TooltipTriggerMode.tap,
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.welcomeMenuTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter email address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email address';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Message ',
                                  style: TextStyle(
                                    fontFamily: 'montserrat',
                                    fontSize: 14,
                                    color: AppColors.welcomeMenuTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                        color: AppColors.welcomeMenuTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Message',
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(10),
                                triggerMode: TooltipTriggerMode.tap,
                                showDuration: const Duration(seconds: 60),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.welcomeMenuTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                            },
                            decoration: InputDecoration(
                              hintText: 'Please sign the agreement',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            maxLines: 5,
                            maxLength: 1000,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFFFE082),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'NOTE: This will send new agreement sign request. Your previous request will be discarded if you have sent any.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Footer Buttons
              BlocBuilder<AgreementsBloc, AgreementsState>(
                builder: (context, state) {
                  final isLoading =
                      state.status == AgreementsStatus.sendingToSignee;

                  return Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: isTablet ? 48.0 : 24.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSendToSignee,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
