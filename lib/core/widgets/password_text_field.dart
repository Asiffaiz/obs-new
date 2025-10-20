import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PasswordTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final String svgPath; // <-- NEW

  const PasswordTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.svgPath, // <-- NEW
    this.validator,
    this.enabled = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: widget.enabled,

      decoration: InputDecoration(
        // labelText: widget.label,
        hintText: widget.label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            widget.svgPath,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed:
              widget.enabled
                  ? () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  }
                  : null,
        ),
      ),
      validator: widget.validator,
    );
  }
}
