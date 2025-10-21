import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';

import '../controllers/app_ctrl.dart' as app_ctrl;
import '../widgets/button.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool isCallActive = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showCallMeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.purple.withOpacity(0.3),
                //     blurRadius: 15,
                //     spreadRadius: 5,
                //   ),
                // ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User icon logo at the top
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HexColor("#0033A0"),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.purple.withOpacity(0.3),
                      //     blurRadius: 10,
                      //     spreadRadius: 2,
                      //   ),
                      // ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter your phone number',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.phone, color: HexColor("#0033A0")),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 198, 196, 232),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HexColor("#0033A0"),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              // Process phone number here
                              if (_phoneController.text.isNotEmpty) {
                                // Call service would be implemented here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Calling you at ${_phoneController.text}',
                                    ),
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      144,
                                      32,
                                      133,
                                    ),
                                  ),
                                );
                              }
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _dialIn() async {
    // Replace with your actual phone number
    const phoneNumber = '+18001234567';
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  void _toggleCall() {
    final appCtrl = context.read<app_ctrl.AppCtrl>();

    setState(() {
      isCallActive = !isCallActive;
    });

    if (isCallActive) {
      // Connect call
      appCtrl.connect();
      // Start animation with higher speed for active call
      _animationController.duration = const Duration(milliseconds: 800);
      _animationController.repeat(reverse: true);
    } else {
      // Disconnect call
      appCtrl.disconnect();
      // Slow down animation for inactive state
      _animationController.duration = const Duration(seconds: 2);
      _animationController.repeat(reverse: true);
    }
  }

  // Update UI when connection state changes
  void _updateUIBasedOnConnectionState(
    app_ctrl.ConnectionState connectionState,
  ) {
    if (connectionState == app_ctrl.ConnectionState.disconnected &&
        isCallActive) {
      setState(() {
        isCallActive = false;
      });
      // Reset animation to slower speed
      _animationController.duration = const Duration(seconds: 2);
      _animationController.repeat(reverse: true);
    }
  }

  // Build a shiny glassmorphic button with icon and label
  Widget _buildGlassmorphicButton({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 211, 120, 227).withOpacity(0.8),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HexColor("#4A90E2"), HexColor("#0033A0")],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
              boxShadow: [
                BoxShadow(
                  color: HexColor("#0033A0").withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade300],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // appBar: AppBar(
        //   title: const Text('VOICE ADMINS'),
        //   centerTitle: true,
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   iconTheme: const IconThemeData(color: Colors.white),
        // ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon:
                          Platform.isAndroid
                              ? const Icon(Icons.arrow_back)
                              : const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.settings),
                    //   onPressed: () {},
                    // ),
                  ],
                ),
              ),
              // const Spacer(),
              const Text(
                'Hello, Asif!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text(
                'How can I help you today?',
                style: TextStyle(fontSize: 18, color: Colors.indigo),
              ),
              const SizedBox(height: 40),
              // Audio Visualizer
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.purple.shade300, Colors.purple.shade500],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade200.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated circles for audio visualization
                          if (isCallActive)
                            ...List.generate(3, (index) {
                              return AnimatedOpacity(
                                opacity: isCallActive ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  width: 120 + (index * 30 * _animation.value),
                                  height: 120 + (index * 30 * _animation.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                      0.1 - (index * 0.03),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          // Mic icon
                          Icon(
                            isCallActive ? Icons.mic : Icons.mic_none,
                            size: 80,
                            color: Colors.white,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Talk Now / Cancel Button
              Builder(
                builder: (context) {
                  // Listen for connection state changes
                  final connectionState =
                      context.watch<app_ctrl.AppCtrl>().connectionState;

                  // Update UI based on connection state
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateUIBasedOnConnectionState(connectionState);
                  });

                  return Button(
                    text:
                        isCallActive
                            ? connectionState ==
                                    app_ctrl.ConnectionState.connecting
                                ? 'Connecting'
                                : 'Disconnect'
                            : 'Talk Now',
                    onPressed: _toggleCall,
                    isProgressing:
                        connectionState == app_ctrl.ConnectionState.connecting,
                  );
                },
              ),
              const Spacer(),
              // Glassmorphic Dial In and Call Me buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildGlassmorphicButton(
                        icon: const Icon(
                          Icons.dialpad_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: 'Dial In',
                        onPressed: _dialIn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGlassmorphicButton(
                        icon: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: 'Call Me',
                        onPressed: () => _showCallMeDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Terms and Privacy
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse(ApiEndpoints.termsAndConditions));
                      },
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: Colors.indigo,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text('|', style: TextStyle(color: Colors.indigo)),
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse(ApiEndpoints.privacyPolicy));
                      },
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Colors.indigo,
                          decoration: TextDecoration.underline,
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
}
