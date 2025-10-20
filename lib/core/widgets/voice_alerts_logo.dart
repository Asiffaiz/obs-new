import 'package:flutter/material.dart';

/// Widget to display the Voice Alerts logo
/// This is a placeholder that will be replaced with an actual image
class VoiceAlertsLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;

  const VoiceAlertsLogo({super.key, this.size = 100, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: Image.asset('assets/images/logo1.png', fit: BoxFit.contain),
    );
  }
}
