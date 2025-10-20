import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voicealerts_obs/features/auth/presentation/bloc/auth_event.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';
import '../bloc/business_card_bloc.dart';
import '../bloc/business_card_event.dart';
import '../bloc/business_card_state.dart';
import '../widgets/loading_state.dart';

class BusinessCardScanScreen extends StatefulWidget {
  const BusinessCardScanScreen({super.key});

  @override
  State<BusinessCardScanScreen> createState() => _BusinessCardScanScreenState();
}

class _BusinessCardScanScreenState extends State<BusinessCardScanScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isImageCaptured = false;
  String? _capturedImagePath;
  bool _isProcessing = false;
  bool _isInternetConnected = true;
  // Feature flag to control visibility of offline indicators
  final bool _showOfflineIndicators = false;
  String? _isCameraError;

  @override
  void initState() {
    super.initState();
    print('CAMERA DEBUG: BusinessCardScanScreen initState');
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('CAMERA DEBUG: AppLifecycleState changed to: $state');

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('CAMERA DEBUG: Camera not initialized during lifecycle change');
      return;
    }

    if (state == AppLifecycleState.inactive) {
      print('CAMERA DEBUG: App inactive, disposing camera');
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      print('CAMERA DEBUG: App resumed, re-initializing camera');
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    print('CAMERA DEBUG: Initializing camera');

    try {
      final cameras = await availableCameras();
      print('CAMERA DEBUG: Found ${cameras.length} cameras');

      if (cameras.isEmpty) {
        print('CAMERA DEBUG: No cameras found');
        setState(() {
          _isCameraError = 'No cameras available on device';
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController?.initialize();
      print('CAMERA DEBUG: Camera initialized');

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('CAMERA DEBUG: Camera initialization error: $e');
      setState(() {
        _isCameraError = e.toString();
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      // Show loading while capturing to indicate something is happening
      _isProcessing = true;
    });

    try {
      // Check internet connectivity before capturing
      await _checkInternetConnection();

      // Take the full picture
      final XFile image = await _cameraController!.takePicture();

      // Immediately crop the image to match what's shown in the preview
      final String croppedPath = await _cropBusinessCardArea(image.path);

      setState(() {
        _capturedImagePath = croppedPath;
        _isImageCaptured = true;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
    }
  }

  void _retakeImage() {
    setState(() {
      _isImageCaptured = false;
      _capturedImagePath = null;
    });
  }

  Future<void> _checkInternetConnection() async {
    // Always set to true for now, but keep the check logic for future use
    setState(() {
      _isInternetConnected = true;
    });

    // Original code commented out but kept for future use
    /*
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isInternetConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } on SocketException catch (_) {
      setState(() {
        _isInternetConnected = false;
      });
    }
    */
  }

  Future<void> _processImage() async {
    if (_capturedImagePath == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check internet connection before processing
      await _checkInternetConnection();

      // Add the image to the bloc with information about connectivity
      context.read<BusinessCardBloc>().add(
        SaveBusinessCard(
          _capturedImagePath!,
          useLocalProcessing: !_isInternetConnected,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
    }
  }

  Future<String> _cropBusinessCardArea(String imagePath) async {
    try {
      // Read the image file
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Get image dimensions
      final int width = originalImage.width;
      final int height = originalImage.height;

      print('Original captured image dimensions: $width x $height');

      // We want a tighter crop that matches what the user sees in the preview frame
      // Use a more aggressive crop ratio to remove surrounding content

      // For landscape images (typical when taking a picture of a monitor/screen)
      // We want to focus on a smaller area where the card would be located
      double cropWidthRatio = 0.85; // Increased from 0.75 to 0.85
      double cropHeightRatio = 0.45; // Increased from 0.4 to 0.45
      double verticalPosition = 0.25; // Position the crop box higher up

      // Calculate card area
      final int cardWidth = (width * cropWidthRatio).round();
      final int cardHeight = (height * cropHeightRatio).round();

      // Center horizontally, position vertically to focus on card
      final int x = ((width - cardWidth) / 2).round();
      final int y = (height * verticalPosition).round();

      print(
        'Crop parameters: Width: $cardWidth, Height: $cardHeight, X: $x, Y: $y',
      );

      // Crop the image
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: cardWidth,
        height: cardHeight,
      );

      // Generate a new file path for the cropped image
      final String croppedPath = imagePath.replaceFirst('.jpg', '_cropped.jpg');

      // Save the cropped image
      final File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      print(
        'Successfully cropped image to: $cardWidth x $cardHeight at position ($x, $y)',
      );

      return croppedPath;
    } catch (e) {
      print('Error cropping image: $e');
      // Return the original path if cropping fails
      return imagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Scan Business Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isCameraError != null) {
      return _buildCameraErrorView();
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0062CC)),
            SizedBox(height: 24),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }

    if (_isImageCaptured) {
      return _buildImagePreview();
    }

    return _buildCameraPreview();
  }

  //////////

  void _checkUser(BusinessCard businessCard) async {
    context.read<BusinessCardBloc>().add(
      SignInWithBusinessCardRequested(
        email: businessCard.email,
        businessCardUser: businessCard,
      ),
    );
  }

  Widget _buildCameraErrorView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 24.0),
          const Text(
            'Camera Error',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          Text(
            'We encountered an error with your camera:\n${_isCameraError ?? "Unknown error"}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16.0,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0062CC),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    // Adjust dimensions to prevent overflow
    final cardWidth = size.width * 0.9; // 90% of screen width
    // Calculate a safe height that won't cause overflow
    final availableHeight =
        size.height -
        kToolbarHeight - // AppBar height
        MediaQuery.of(context).padding.top - // Status bar
        56 - // Footer height
        80 - // Bottom button container
        100; // Additional padding and instruction text

    final cardHeight = availableHeight * 0.7; // Use 70% of available space

    // Build the camera preview container with frame and guides
    Widget buildCameraPreviewContainer({required Widget cameraWidget}) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview with natural aspect ratio
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(child: cameraWidget),
          ),

          // Loading indicator when capturing
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Business card guideline - crop area indicator
          Center(
            child: Container(
              width: cardWidth * 0.85,
              height: cardHeight * 0.45 / 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Corner guides
          ..._buildCornerGuides(cardWidth * 0.85, cardHeight * 0.45 / 0.7),
        ],
      );
    }

    // Build the main UI structure
    return Column(
      children: [
        const SizedBox(height: 8), // Reduced top padding
        // Internet status indicator - add at the top
        if (!_isInternetConnected && _showOfflineIndicators)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Offline mode: Will use local processing (may be less accurate)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Main content area
        Expanded(
          child: SingleChildScrollView(
            // Add scrolling capability to handle potential overflow
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum space needed
                children: [
                  // Camera preview with business card frame
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: cardWidth,
                    height: cardHeight,
                    child: buildCameraPreviewContainer(
                      cameraWidget: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),

                  // Instruction text
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Position the business card inside the white frame',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Capture button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _captureImage,
                        customBorder: const CircleBorder(),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 32,
                            color: Color(0xFF4863F1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Powered by text
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Powered by ',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              //  Image.asset('assets/images/onboard-logo.png', height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build corner guide indicators
  List<Widget> _buildCornerGuides(double width, double height) {
    const guideSize = 20.0;
    const guideThickness = 3.0;
    const guideColor = Colors.white;

    return [
      // Top left corner
      Positioned(
        left: (MediaQuery.of(context).size.width - width) / 2,
        top: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideSize,
          height: guideThickness,
          color: guideColor,
        ),
      ),
      Positioned(
        left: (MediaQuery.of(context).size.width - width) / 2,
        top: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideThickness,
          height: guideSize,
          color: guideColor,
        ),
      ),

      // Top right corner
      Positioned(
        right: (MediaQuery.of(context).size.width - width) / 2,
        top: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideSize,
          height: guideThickness,
          color: guideColor,
        ),
      ),
      Positioned(
        right: (MediaQuery.of(context).size.width - width) / 2,
        top: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideThickness,
          height: guideSize,
          color: guideColor,
        ),
      ),

      // Bottom left corner
      Positioned(
        left: (MediaQuery.of(context).size.width - width) / 2,
        bottom: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideSize,
          height: guideThickness,
          color: guideColor,
        ),
      ),
      Positioned(
        left: (MediaQuery.of(context).size.width - width) / 2,
        bottom: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideThickness,
          height: guideSize,
          color: guideColor,
        ),
      ),

      // Bottom right corner
      Positioned(
        right: (MediaQuery.of(context).size.width - width) / 2,
        bottom: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideSize,
          height: guideThickness,
          color: guideColor,
        ),
      ),
      Positioned(
        right: (MediaQuery.of(context).size.width - width) / 2,
        bottom: (MediaQuery.of(context).size.height - height) / 6,
        child: Container(
          width: guideThickness,
          height: guideSize,
          color: guideColor,
        ),
      ),
    ];
  }

  Widget _buildImagePreview() {
    return BlocListener<BusinessCardBloc, BusinessCardState>(
      listener: (context, state) {
        if (state is BusinessCardDetailLoaded) {
          //   Navigate to the form screen if saved successfully
          // context.go(
          //   '${AppRoutes.cardForm.replaceFirst(":id", state.id.toString())}',
          //   extra: _capturedImagePath,
          // );

          _checkUser(state.businessCard);
        } else if (state is BusinessCardUserExists) {
          //Here will navigate to next screen because user already exists
          print(state.user);
          setState(() {
            _isProcessing = false;
          });
        } else if (state is BusinessCardSigninRequestedSuccess) {
          print(state.additionalData);
          setState(() {
            _isProcessing = false;
          });
          context.push(AppRoutes.signUp, extra: state.additionalData);
        } else if (state is BusinessCardError) {
          // Show error message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          setState(() {
            _isProcessing = false;
          });
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Display captured image
                Image.file(File(_capturedImagePath!), fit: BoxFit.contain),

                // Show loading overlay when processing
                if (_isProcessing)
                  Container(
                    color: Colors.black.withAlpha(128),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Processing...',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _retakeImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processImage,
                    icon: const Icon(Icons.check),
                    label: const Text('Process'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Not connected indicator
          if (!_isInternetConnected && _showOfflineIndicators)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Offline mode: Using local processing (may be less accurate)',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Powered by text
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Powered by ',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                //   Image.asset('assets/images/onboard-logo.png', height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
