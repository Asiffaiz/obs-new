import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:signature/signature.dart';

class AgreementSignaturePad extends StatefulWidget {
  final Function(Uint8List)? onSignatureCompleted;
  final VoidCallback? onClear;
  final double height;
  final double width;
  final bool isFullScreen;
  final Uint8List? initialSignature;

  const AgreementSignaturePad({
    super.key,
    this.onSignatureCompleted,
    this.onClear,
    this.height = 200,
    this.width = double.infinity,
    this.isFullScreen = false,
    this.initialSignature,
  });

  @override
  State<AgreementSignaturePad> createState() => _AgreementSignaturePadState();
}

class _AgreementSignaturePadState extends State<AgreementSignaturePad> {
  late SignatureController _controller;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Load initial signature if provided
    if (widget.initialSignature != null) {
      _loadSignature(widget.initialSignature!);
    }

    _controller.addListener(() {
      setState(() {
        _isSigning = _controller.isNotEmpty;
      });
      if (_isSigning && widget.onSignatureCompleted != null) {
        _exportSignature();
      }
    });
  }

  @override
  void didUpdateWidget(AgreementSignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the initialSignature has changed and is not null, load it
    if (widget.initialSignature != null &&
        widget.initialSignature != oldWidget.initialSignature) {
      _loadSignature(widget.initialSignature!);
    }
  }

  Future<void> _loadSignature(Uint8List bytes) async {
    try {
      _controller.clear();
      final image = await decodeImageFromList(bytes);
      setState(() {
        _isSigning = true;
      });
      // Note: SignatureController doesn't have a direct method to load from bytes
      // We're setting _isSigning to true to indicate there's a signature
    } catch (e) {
      // Handle error loading signature
      print('Error loading signature: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportSignature() async {
    if (_controller.isEmpty) return;

    final exportedImage = await _controller.toPngBytes();
    if (exportedImage != null && widget.onSignatureCompleted != null) {
      widget.onSignatureCompleted!(exportedImage);
    }
  }

  void _clearSignature() {
    _controller.clear();
    if (widget.onClear != null) {
      widget.onClear!();
    }
    setState(() {
      _isSigning = false;
    });
  }

  // Method to get current signature bytes
  Future<Uint8List?> getSignatureBytes() async {
    if (_controller.isEmpty) return null;
    return await _controller.toPngBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Signature area
        Container(
          height: widget.isFullScreen ? double.infinity : widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.white,
              height: widget.isFullScreen ? double.infinity : widget.height,
              width: widget.width,
            ),
          ),
        ),

        // Dotted line for signature
        Positioned(
          left: 20,
          right: 20,
          bottom: widget.isFullScreen ? 80 : 40,
          child: CustomPaint(
            painter: DottedLinePainter(),
            size: const Size(double.infinity, 1),
          ),
        ),

        // Placeholder text when empty
        if (!_isSigning)
          Positioned(
            left: 0,
            right: 0,
            bottom:
                widget.isFullScreen ? widget.height / 1.5 : widget.height / 2,
            child: Center(
              child: Text(
                'Sign here',
                style: TextStyle(
                  fontSize: widget.isFullScreen ? 32 : 24,
                  color: Colors.grey.shade300,
                  fontStyle: FontStyle.italic,
                ),
              ),
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
