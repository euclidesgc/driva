import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class NumberTextField extends StatelessWidget {
  const NumberTextField({
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.hintText = '—',
    this.suffixIcon,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? helperText;
  final String hintText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: AppTypography.base),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        errorText: errorText,
        helperText: errorText == null ? helperText : null,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIcon == null
            ? null
            : const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
      onChanged: onChanged,
    );
  }
}
