import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class EmptySlotMarker extends StatelessWidget {
  const EmptySlotMarker({required this.hint, required this.child, super.key});

  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(AppSpacing.s8),
          alignment: Alignment.center,
          child: Semantics(
            label: 'Espaço vazio: $hint',
            child: Text(
              hint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ),
        ),
      ],
    );
  }
}
