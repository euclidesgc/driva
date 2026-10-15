import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Não guarda estado: quem chama lê a prop booleana e grava com [onChanged].
/// As props de [child] nunca são tocadas, então desligar não as apaga.
class SwitchExpandRow extends StatelessWidget {
  const SwitchExpandRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.child,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s12),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTypography.md,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (value) child,
      ],
    );
  }
}
