import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voicealerts_obs/core/constants/global_veriables_state.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/features/agreements/presentation/widgets/agreement_webview.dart';
import '../../../../config/routes.dart';
import '../../domain/models/agreement_model.dart';
import '../bloc/agreements_bloc.dart';
import '../bloc/agreements_event.dart';
import '../bloc/agreements_state.dart';
import '../widgets/agreement_html_viewer.dart';
import '../widgets/agreement_signature_pad.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AgreementDetailScreen extends StatefulWidget {
  final AgreementModel agreement;
  final bool isLastAgreement;
  final VoidCallback? onComplete;
  final VoidCallback? onRefreshOptionalAgreements;
  final String comeFrom;
  const AgreementDetailScreen({
    super.key,
    required this.agreement,
    this.isLastAgreement = false,
    this.onComplete,
    required this.comeFrom,
    this.onRefreshOptionalAgreements,
  });

  @override
  State<AgreementDetailScreen> createState() => _AgreementDetailScreenState();
}

class _AgreementDetailScreenState extends State<AgreementDetailScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AgreementFormWebViewState> _childKey =
      GlobalKey<AgreementFormWebViewState>();

  bool _hasScrolledToBottom = true;
  AgreementViewMode _currentViewMode = AgreementViewMode.detail;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  Uint8List? _signatureBytes;
  bool _isSignatureMode = false;
  bool _isExpandedSignatureMode = false;
  final GlobalKey _signaturePadKey = GlobalKey();
  SignatureController? _signatureController;
  bool _isDrawMode = true;
  bool _isTextMode = false;
  bool _isAccepted = false;
  Uint8List? _selectedImageBytes;
  var isTablet = false;
  final TextEditingController _signatureTextController =
      TextEditingController();
  String _selectedFont = 'Lato';
  String _signMethod = 'draw';
  String filledAgreementContent = '';

  final FocusNode _messageFocusNode = FocusNode();

  // List of available signature fonts
  final List<String> _signatureFonts = [
    'Lato',
    'Delius',
    'Meow Script',
    'Delius Swash Caps',
    'Caveat',
    'Merienda',
    'Dancing Script',
    'Pacifico',
    'Indie Flower',
    'Patrick Hand',
    'Pangolin',
    'Permanent Marker',
    'Gochi Hand',
    'Bangers',
  ];

  // Animation controller for success dialog
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

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
    _signatureController?.dispose();
    _signatureTextController.dispose();
    _animationController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<String> _getTextFromChild() async {
    final result = await _childKey.currentState?.getHtmlBack();

    return result.toString();
  }

  void _handleScrollToBottom(bool scrolledToBottom) {
    setState(() {
      _hasScrolledToBottom = scrolledToBottom;
    });
  }

  void _showSignaturePad() {
    setState(() {
      _isSignatureMode = true;
    });
  }

  void _hideSignaturePad() {
    setState(() {
      _isSignatureMode = false;
    });
  }

  void _showSendToSigneeForm() {
    setState(() {
      _currentViewMode = AgreementViewMode.sendToSignee;
    });
  }

  void _handleSignatureCompleted(Uint8List signatureBytes) {
    setState(() {
      _signatureBytes = signatureBytes;
    });
  }

  void _handleSignatureClear() {
    setState(() {
      _signatureBytes = null;
      if (_isTextMode) {
        _signatureTextController.clear();
      }
    });
  }

  void _exportSignature() async {
    if (_signatureController != null && !_signatureController!.isEmpty) {
      final exportedImage = await _signatureController!.toPngBytes();
      if (exportedImage != null) {
        _handleSignatureCompleted(exportedImage);
      }
    }
  }

  void _handleSendToSignee() {
    if (_formKey.currentState!.validate()) {
      context.read<AgreementsBloc>().add(
        SendToSignee(
          agreementId: widget.agreement.id.toString(),
          name: _nameController.text,
          email: _emailController.text,
          title: _titleController.text,
          message: _messageController.text,
        ),
      );
    }
  }

  void _acceptAgreementAcceptOnly() async {
    filledAgreementContent = await _getTextFromChild();
    print(filledAgreementContent);
    if (filledAgreementContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill the agreement before accepting'),
          // backgroundColor: Colors.red,
        ),
      );
      return;
    } else {
      // Get the required data for API payload
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString('client_acn__') ?? '';
      final email = prefs.getString('client_eml__') ?? '';

      Map<String, dynamic>? payload;
      // Create the payload
      if (widget.agreement.type == "accept") {
        if (!_isAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please accept the agreement before signing'),
            ),
          );
          return;
        }

        payload = {
          'accountno': accountNo,
          'email': email,
          'agreement_id': widget.agreement.id.toString(),
          'signature': '',
          'agreement_content': filledAgreementContent,
          'agreement_accountno': widget.agreement.agreementAccountNo,
          'agreement_type': widget.agreement.type,
        };
      }

      if (widget.comeFrom == 'mandatory') {
        // Send to the bloc
        context.read<AgreementsBloc>().add(
          SaveSignature(
            agreementId: widget.agreement.id.toString(),
            signatureUrl: '',
            signMethod: _signMethod,
            payload: payload,
          ),
        );
      } else if (widget.comeFrom == 'optional') {
        // Send to the bloc
        context.read<AgreementsBloc>().add(
          SaveOptionalSignature(
            agreementId: widget.agreement.id.toString(),
            signatureUrl: '',
            signMethod: _signMethod,
            payload: payload,
          ),
        );
      }
    }
  }

  void _acceptAgreement() async {
    filledAgreementContent = await _getTextFromChild();
    print(filledAgreementContent);
    if (filledAgreementContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill the agreement before accepting'),
          // backgroundColor: Colors.red,
        ),
      );
      return;
    } else {
      print('here');
      if (_isDrawMode &&
          _signatureController != null &&
          !_signatureController!.isEmpty) {
        // Export signature and wait for it to complete
        final exportedImage = await _signatureController!.toPngBytes(
          // height: 300,
          // width: 300,
        );
        if (exportedImage != null) {
          _signatureBytes = exportedImage;
        }
      } else if (_isTextMode) {
        // Convert text to image
        final textImage = await _convertTextToImage();
        if (textImage != null) {
          _signatureBytes = textImage;
        }
      }
      print(_signatureBytes);
      if (_signatureBytes != null) {
        // Convert signature bytes to base64 string
        final base64Signature = base64Encode(_signatureBytes!);

        // Get the required data for API payload
        final prefs = await SharedPreferences.getInstance();
        final accountNo = prefs.getString('client_acn__') ?? '';
        final email = prefs.getString('client_eml__') ?? '';

        Map<String, dynamic>? payload;
        // Create the payload

        if (widget.agreement.type == "esign") {
          if (_signMethod == 'write') {
            payload = {
              'accountno': accountNo,
              'email': email,
              'agreement_id': widget.agreement.id.toString(),
              'imgData': base64Signature,
              'agreement_content': filledAgreementContent,
              'agreement_accountno': widget.agreement.agreementAccountNo,
              'agreement_type': widget.agreement.type,
            };
          }

          if (_signMethod == 'draw' || _signMethod == 'choose') {
            payload = {
              'accountno': accountNo,
              'email': email,
              'agreement_id': widget.agreement.id.toString(),
              'signature': base64Signature,
              'agreement_content': filledAgreementContent,
              'agreement_accountno': widget.agreement.agreementAccountNo,
              'agreement_type': widget.agreement.type,
            };
          }
        }

        if (widget.comeFrom == 'mandatory') {
          // Send to the bloc
          context.read<AgreementsBloc>().add(
            SaveSignature(
              agreementId: widget.agreement.id.toString(),
              signatureUrl: base64Signature,
              signMethod: _signMethod,
              payload: payload,
            ),
          );
        } else if (widget.comeFrom == 'optional') {
          // Send to the bloc
          context.read<AgreementsBloc>().add(
            SaveOptionalSignature(
              agreementId: widget.agreement.id.toString(),
              signatureUrl: base64Signature,
              signMethod: _signMethod,
              payload: payload,
            ),
          );
        }
      } else {
        // Show error if no signature
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign the agreement before accepting'),
            // backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToNextAgreement() {
    context.read<AgreementsBloc>().add(const NextAgreement());
  }

  void _goBack() {
    setState(() {
      _currentViewMode = AgreementViewMode.detail;
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _isDrawMode = false;
          _signatureController?.clear();
          _signMethod = 'choose';
        });
        _handleSignatureCompleted(bytes);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image from gallery'),
          // backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enableDrawMode() {
    setState(() {
      _isDrawMode = true;
      _isTextMode = false;
      _selectedImageBytes = null;
      _signMethod = 'draw';
    });
  }

  void _enableTextMode() {
    setState(() {
      _isDrawMode = false;
      _isTextMode = true;
      _selectedImageBytes = null;
      _signatureController?.clear();
      _signMethod = 'write';
    });
  }

  Future<Uint8List?> _convertTextToImage() async {
    if (_signatureTextController.text.isEmpty) return null;

    // Create a picture recorder
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Set up text style with selected font
    // final textStyle = TextStyle(
    //   fontFamily: _selectedFont,
    //   fontSize: 48,
    //   color: Colors.black,
    //   fontWeight: FontWeight.normal,
    // );

    final textStyle = GoogleFonts.getFont(
      _selectedFont,
      fontSize: 48,
      color: Colors.black,
    );

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(text: _signatureTextController.text, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    // Layout the text
    textPainter.layout(maxWidth: 500);

    // Calculate canvas size with some padding
    final width = textPainter.width + 40;
    final height = textPainter.height + 40;

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    // Draw text centered
    textPainter.paint(canvas, Offset(20, 20));

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  void _showSuccessDialog(BuildContext context) {
    // Reset and start the animation
    _animationController.reset();
    _animationController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // Navigate to dashboard when back button is pressed
            context.go(AppRoutes.home);
            return false; // Prevent default back behavior
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildSuccessDialogContent(context),
          ),
        );
      },
    );
  }

  Widget _buildSuccessDialogContent(BuildContext context) {
    return ScaleTransition(
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
                  'Thank You!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You have successfully signed all required agreements.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can now access all features of the application.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.green.shade50,
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(
                //       color: AppColors.primaryColor.withOpacity(0.5),
                //     ),
                //   ),
                //   child: Row(
                //     children: [
                //       Icon(
                //         Icons.check_circle_outline,
                //         color: AppColors.primaryColor,
                //         size: 24,
                //       ),
                //       const SizedBox(width: 12),
                //       Expanded(
                //         child: Text(
                //           'Your account is now fully compliant with our requirements.',
                //           style: TextStyle(
                //             fontSize: 13,
                //             color: Colors.green.shade900,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.home);
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
                      'Continue to Dashboard',
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
          Positioned(
            top: -50,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animationController.value,
                  child: child,
                );
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                            Navigator.of(context).pop();
                            // context.go(AppRoutes.optionalAgreements);

                            if (widget.comeFrom == 'optional') {
                              context.pop();
                              // context.pop();
                              if (widget.onRefreshOptionalAgreements != null) {
                                widget.onRefreshOptionalAgreements!();
                              }
                            } else if (widget.comeFrom == 'mandatory') {
                              context.go(AppRoutes.agreements);
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
    final screenSize = MediaQuery.of(context).size;
    isTablet = screenSize.width >= 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    return BlocConsumer<AgreementsBloc, AgreementsState>(
      listener: (context, state) {
        if (state.status == AgreementsStatus.savedSignature ||
            state.status == AgreementsStatus.acceptedAgreement) {
          if (state.allMandatoryAgreementsSigned) {
            // Show success dialog instead of snackbar
            _showSuccessDialog(context);
          }
          // else if (widget.isLastAgreement && widget.onComplete != null) {
          //   // widget.onComplete!();
          // }
          else {
            _navigateToNextAgreement();
          }
        } else if (state.status == AgreementsStatus.sentToSignee) {
          // Show success popup for sent to signee
          _showSentToSigneeSuccessDialog(context);
        } else if (state.status == AgreementsStatus.showNextAgreement) {
          if (widget.comeFrom == 'optional') {
            context.pop();
            // context.pop();
            if (widget.onRefreshOptionalAgreements != null) {
              widget.onRefreshOptionalAgreements!();
            }
          } else if (widget.comeFrom == 'mandatory') {
            AppState.instance.isShowMandatoryDialog = false;
            // context.go(AppRoutes.agreements);
            context.pushReplacement(AppRoutes.agreements);
          }
        }
      },
      builder: (context, state) {
        // Show a full screen loader when sending to signee
        if (state.status == AgreementsStatus.sendingToSignee) {
          return Scaffold(
            // resizeToAvoidBottomInset: true,
            appBar: AppBar(title: Text(widget.agreement.title), elevation: 0),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Sending agreement...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(widget.agreement.title),
            elevation: 0,
            leading:
                _currentViewMode != AgreementViewMode.detail
                    ? IconButton(
                      icon: Icon(
                        Platform.isIOS
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_back,
                      ),
                      onPressed: _goBack,
                    )
                    : null,
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 48 : 24,
                horizontal: isTablet ? 48 : 0.0,
              ),
              child: Column(
                children: [
                  Expanded(child: _buildContent(state)),

                  if (_isSignatureMode) _buildSignatureSection(isDesktop),
                  const SizedBox(height: 16),
                  _buildBottomButtons(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcceptanceOnlySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isAccepted,
                    onChanged: (value) {
                      setState(() {
                        _isAccepted = value ?? false;
                      });
                    },
                  ),

                  Text(
                    'I accept the instructions.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Divider(height: 1, thickness: 1),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 100,
                        height: 40,
                        child: ElevatedButton(
                          onPressed:
                              _hasScrolledToBottom
                                  ? _showSendToSigneeForm
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Send to Signee',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        width: 100,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _acceptAgreementAcceptOnly,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Accept and continue',
                            style: TextStyle(fontSize: 14),
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
      ],
    );
  }

  Widget _buildSignatureSection(isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Signature',
                      style: TextStyle(
                        fontFamily: 'montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    // IconButton(
                    //   icon: SvgPicture.asset(
                    //     _isExpandedSignatureMode
                    //         ? 'assets/icons/ic_minimize_signature.svg'
                    //         : 'assets/icons/ic_expand_signature.svg',
                    //     height: _isExpandedSignatureMode ? 24 : 20,
                    //     width: _isExpandedSignatureMode ? 24 : 20,
                    //     colorFilter: ColorFilter.mode(
                    //       Colors.grey.shade600,
                    //       BlendMode.srcIn,
                    //     ),
                    //   ),

                    //   onPressed: () {
                    //     if (!_signatureController!.isEmpty) {
                    //       _exportSignature();
                    //     }

                    //     setState(() {
                    //       _isExpandedSignatureMode = !_isExpandedSignatureMode;
                    //     });
                    //   },
                    //   padding: EdgeInsets.zero,
                    // ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final size = MediaQuery.of(context).size;
                  final isPortrait = size.height > size.width;
                  // final normalHeight = 180.0;
                  final normalHeight =
                      isDesktop
                          ? screenWidth * 0.3
                          : isPortrait
                          ? screenWidth *
                              0.8 // Portrait
                          : screenWidth * 0.1; // Landscape
                  final expandedHeight =
                      isDesktop ? screenWidth * 0.3 : screenWidth * 0.8;

                  return Container(
                    height:
                        _isExpandedSignatureMode
                            ? expandedHeight
                            : normalHeight,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        if (_isExpandedSignatureMode)
                          Container(
                            width: expandedHeight,
                            height: screenWidth,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _isDrawMode
                                    ? Signature(
                                      controller: _signatureController!,
                                      backgroundColor: Colors.white,

                                      // height: screenWidth,
                                      // width: expandedHeight,
                                    )
                                    : _isTextMode
                                    ? _buildTextSignatureInput(
                                      expandedHeight * 0.8,
                                    )
                                    : _selectedImageBytes != null
                                    ? Center(
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.contain,
                                        height: expandedHeight * 0.8,
                                      ),
                                    )
                                    : Container(),
                          )
                        else
                          Container(
                            height: normalHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _isDrawMode
                                    ? Signature(
                                      controller: _signatureController!,
                                      backgroundColor: Colors.white,
                                      height: normalHeight,
                                      width: double.infinity,
                                    )
                                    : _isTextMode
                                    ? _buildTextSignatureInput(
                                      normalHeight * 0.8,
                                    )
                                    : _selectedImageBytes != null
                                    ? Center(
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.contain,
                                        height: normalHeight * 0.8,
                                      ),
                                    )
                                    : Container(),
                          ),

                        if (_isDrawMode)
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom:
                                _isExpandedSignatureMode
                                    ? expandedHeight / 7.0
                                    : normalHeight / 6.5,
                            child: CustomPaint(
                              painter: DottedLinePainter(),
                              size: Size(double.infinity, 1),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Please sign above',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),

                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _enableDrawMode,
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: _isDrawMode ? Colors.blue : Colors.grey,
                          ),
                          label: Text(
                            'Draw',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDrawMode ? Colors.blue : Colors.grey,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _enableTextMode,
                          icon: Icon(
                            Icons.text_fields,
                            size: 16,
                            color: _isTextMode ? Colors.blue : Colors.grey,
                          ),
                          label: Text(
                            'Write',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isTextMode ? Colors.blue : Colors.grey,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: Icon(
                            Icons.photo_library,
                            size: 16,
                            color:
                                (!_isDrawMode && !_isTextMode)
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          label: Text(
                            'Choose',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  (!_isDrawMode && !_isTextMode)
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),

                        // TextButton.icon(
                        //   onPressed: () {
                        //     _signatureController?.clear();
                        //     _handleSignatureClear();
                        //     setState(() {
                        //       _selectedImageBytes = null;
                        //       if (_isTextMode) {
                        //         _signatureTextController.clear();
                        //       }
                        //     });
                        //   },
                        //   icon: const Icon(Icons.refresh, size: 16),
                        //   label: const Text(
                        //     'Clear',
                        //     style: TextStyle(fontSize: 12),
                        //   ),
                        //   style: TextButton.styleFrom(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 8,
                        //       vertical: 4,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextSignatureInput(double height) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text input field
          TextField(
            controller: _signatureTextController,
            decoration: InputDecoration(
              hintText: 'Type your signature',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              // Force rebuild to update the preview
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          // Font selector dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: _selectedFont,
              isExpanded: true,
              underline: Container(),
              hint: const Text('Select Font'),
              items:
                  _signatureFonts.map((String font) {
                    final displayText =
                        _signatureTextController.text.isEmpty
                            ? "Sample Text"
                            : _signatureTextController.text;
                    return DropdownMenuItem<String>(
                      value: font,
                      child: Text(
                        displayText,
                        style: GoogleFonts.getFont(font),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFont = newValue;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          // Preview
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                _signatureTextController.text.isEmpty
                    ? Text(
                      'Your signature will appear here',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    )
                    : Text(
                      _signatureTextController.text,
                      style: GoogleFonts.getFont(
                        _selectedFont,
                      ).copyWith(fontSize: 36),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AgreementsState state) {
    switch (_currentViewMode) {
      case AgreementViewMode.detail:
        return AgreementFormWebView(
          agreement: widget.agreement,
          key: _childKey,
        );
      // AgreementHtmlViewer(
      //   agreement: widget.agreement,
      //   onScrolledToBottom: _handleScrollToBottom,
      // );
      case AgreementViewMode.sign:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign Agreement',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign below to accept "${widget.agreement.title}"',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Signature(
                controller: _signatureController!,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        );
      case AgreementViewMode.sendToSignee:
        return _buildSendToSigneeForm();
      default:
        return AgreementFormWebView(
          agreement: widget.agreement,
          key: _childKey,
        );
    }
  }

  Widget _buildSendToSigneeForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 24.0,
            horizontal: isTablet ? 48.0 : 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send To Signee',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                        RichText(
                          text: TextSpan(
                            text: 'Full Name ',
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
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter full name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
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
                        Text(
                          'Title',
                          style: TextStyle(
                            fontFamily: 'montserrat',
                            fontSize: 14,
                            color: AppColors.welcomeMenuTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
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
                      style: TextStyle(color: AppColors.welcomeMenuTextColor),
                    ),
                  ],
                ),
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
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                      style: TextStyle(color: AppColors.welcomeMenuTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                textInputAction: TextInputAction.done, // ✅ Shows Done button
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus(); // ✅ Close keyboard
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
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
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
    );
  }

  Widget _buildBottomButtons(AgreementsState state) {
    if (state.status == AgreementsStatus.loading ||
        state.status == AgreementsStatus.signing ||
        state.status == AgreementsStatus.acceptingAgreement ||
        state.status == AgreementsStatus.savingSignature) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSignatureMode) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconWithLabel(
              icon: SvgPicture.asset(
                'assets/icons/ic_go_back.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  Colors.grey.shade600,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Back',
              onPressed: _hideSignaturePad,
            ),
            _buildIconWithLabel(
              icon: SvgPicture.asset(
                'assets/icons/ic_download.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  Colors.grey.shade600,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Download',
              onPressed: () {
                // Download document functionality
              },
            ),
            _buildIconWithLabel(
              icon: SvgPicture.asset(
                'assets/icons/ic_clear.svg',
                height: 22,
                width: 22,
                colorFilter: ColorFilter.mode(
                  Colors.grey.shade600,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Clear',
              onPressed: () {
                _signatureController?.clear();
                _handleSignatureClear();
                setState(() {
                  _selectedImageBytes = null;
                  if (_isTextMode) {
                    _signatureTextController.clear();
                  }
                });
              },
            ),
            // _buildIconWithLabel(
            //   icon: SvgPicture.asset(
            //     'assets/icons/ic_preview.svg',
            //     height: 20,
            //     width: 20,
            //     colorFilter: ColorFilter.mode(
            //       Colors.grey.shade600,
            //       BlendMode.srcIn,
            //     ),
            //   ),
            //   label: 'Preview',
            //   onPressed: () {
            //     // Preview functionality
            //   },
            // ),
            _buildIconWithLabel(
              icon: SvgPicture.asset(
                'assets/icons/ic_save.svg',
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(Colors.blue, BlendMode.srcIn),
              ),
              label: 'Save',
              onPressed: _acceptAgreement,
              isActive: true,
            ),
          ],
        ),
      );
    }

    switch (_currentViewMode) {
      case AgreementViewMode.detail:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              if (widget.agreement.type == "accept")
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAccepted,
                        onChanged: (value) {
                          setState(() {
                            _isAccepted = value ?? false;
                          });
                        },
                      ),

                      Text(
                        'I accept the instructions.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: 100,
                      height: 40,
                      child: ElevatedButton(
                        onPressed:
                            _hasScrolledToBottom ? _showSendToSigneeForm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appButtonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Send to Signee',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.agreement.type == "esign")
                    Expanded(
                      child: SizedBox(
                        width: 100,
                        height: 40,
                        child: ElevatedButton(
                          onPressed:
                              _hasScrolledToBottom ? _showSignaturePad : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign Agreement',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),

                  if (widget.agreement.type == "accept")
                    Expanded(
                      child: SizedBox(
                        width: 100,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _acceptAgreementAcceptOnly,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Accept and continue',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      case AgreementViewMode.sign:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton(
            onPressed: _acceptAgreement,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Accept Agreement'),
          ),
        );
      case AgreementViewMode.sendToSignee:
        return Container(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: isTablet ? 48.0 : 24.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 100,
                height: 40,
                child: OutlinedButton(
                  onPressed: _goBack,
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
                  onPressed: _handleSendToSignee,
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
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIconWithLabel({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: icon,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
