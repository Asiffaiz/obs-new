import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgHelper {
  static Widget svgOrFallback({
    required String svgPath,
    required String fallbackImagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    try {
      return SvgPicture.asset(
        svgPath,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder:
            (context) => Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      );
    } catch (e) {
      debugPrint('Error loading SVG $svgPath: $e');
      return Image.asset(
        fallbackImagePath,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }
}
