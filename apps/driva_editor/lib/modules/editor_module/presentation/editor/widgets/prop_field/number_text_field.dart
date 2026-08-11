import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class NumberTextField extends StatelessWidget {
  const NumberTextField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: AppTypography.base),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(isDense: true, hintText: '—'),
      onChanged: onChanged,
    );
  }
}
