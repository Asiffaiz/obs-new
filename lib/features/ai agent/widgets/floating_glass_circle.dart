import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart' as sf;

class FloatingGlassCircleButton extends StatelessWidget {
  final IconData sfIcon;
  final GestureTapCallback? onTap;
  final Color? iconColor;
  final bool isActive;
  final bool isEnabled;

  final Widget? subWidget;

  const FloatingGlassCircleButton({
    super.key,
    required this.sfIcon,
    this.onTap,
    this.iconColor,
    this.isActive = false,
    this.isEnabled = true,
    this.subWidget,
  });

  @override
  Widget build(BuildContext ctx) => Material(
    borderRadius: BorderRadius.circular(10),
    clipBehavior: Clip.antiAlias,
    type: MaterialType.transparency,
    child: Ink(
      color: isActive ? Theme.of(ctx).cardColor : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isActive
                    ? Colors.blue.shade400
                    : Colors.blue.shade400.withOpacity(0.4),
            // gradient: LinearGradient(
            //   colors:
            //       isActive
            //           ? [Colors.blue.shade400, Colors.blue.shade700]
            //           : [
            //             Colors.grey.shade200,
            //             Colors.grey.shade400.withOpacity(0.2),
            //           ],
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            // ),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.blue.shade300.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          alignment: Alignment.center,
          child: _buildContent(ctx),
        ),
      ),
    ),
  );

  Widget _buildContent(BuildContext context) {
    if (subWidget != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sf.SFIcon(sfIcon, color: iconColor, fontSize: 20),
          subWidget!,
        ],
      );
    }

    return Opacity(
      opacity: onTap == null ? 0.1 : 1.0,
      child: sf.SFIcon(sfIcon, color: iconColor, fontSize: 20),
    );
  }

  Widget _buildCircularControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    isActive
                        ? [Colors.blue.shade400, Colors.blue.shade700]
                        : [Colors.grey.shade200, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color: Colors.blue.shade300.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade800,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue.shade900 : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
