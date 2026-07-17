import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class EdgeInsetsSideField extends StatelessWidget {
  const EdgeInsetsSideField({
    required this.controller,
    required this.label,
    required this.onChanged,
    super.key,
  });

  final TextEditingController? controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: AppTypography.md),
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(fontSize: AppTypography.xs),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
