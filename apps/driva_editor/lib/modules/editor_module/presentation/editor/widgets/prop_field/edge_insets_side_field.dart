import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_typography.dart';

/// Um lado do editor de `EdgeInsets` (E/T/D/B): o `TextField` numérico
/// centralizado que compõe a linha do [EdgeInsetsEditor]. Recebe o controller
/// do lado, o rótulo curto e o callback de texto pelo construtor.
class EdgeInsetsSideField extends StatelessWidget {
  const EdgeInsetsSideField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
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
