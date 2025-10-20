import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

class ResponsivePadding extends StatelessWidget {
  final Widget child;

  const ResponsivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double horizontalPadding = 24.0;

    if (screenWidth >= Breakpoints.tablet) {
      horizontalPadding = screenWidth * 0.15;
    } else if (screenWidth >= Breakpoints.mobile) {
      horizontalPadding = screenWidth * 0.08;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }
}
