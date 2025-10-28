import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';

Widget formLabel(
  String text, {
  bool isRequired = false,
  String tooltipMessage = '',
}) {
  return Row(
    children: [
      RichText(
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
      ),
      const SizedBox(width: 8),
      tooltipMessage.isEmpty
          ? SizedBox.shrink()
          : Tooltip(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.all(10),
            message: tooltipMessage,
            triggerMode: TooltipTriggerMode.tap,
            showDuration: Duration(seconds: 60),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.welcomeMenuTextColor,
            ),
          ),
    ],
  );
}
