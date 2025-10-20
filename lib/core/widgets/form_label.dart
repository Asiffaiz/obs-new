import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';

Widget formLabel(String text, {bool isRequired = false}) {
  return RichText(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'montserrat',
        fontSize: 14,
        color: AppColors.welcomeMenuTextColor,
        fontWeight: FontWeight.bold,
      ),
      children:
          isRequired
              ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.welcomeMenuTextColor),
                ),
              ]
              : [],
    ),
  );
}
