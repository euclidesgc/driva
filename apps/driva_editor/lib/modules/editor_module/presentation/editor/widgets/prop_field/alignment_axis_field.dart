import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Um eixo do alinhamento. Aceita valor fora de -1..1 sem corrigir: o
/// FlutterFlow deixa digitar, e a grade simplesmente não acende nenhuma célula.
class AlignmentAxisField extends StatelessWidget {
  const AlignmentAxisField({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.s16,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.md,
              color: colors.inkSecondary,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: AppTypography.base),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(isDense: true, hintText: '0'),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
