import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// A moldura de uma propriedade no Inspector: rótulo, marca de obrigatória e
/// os botões de canto, com o editor por baixo.
///
/// Existe separada para que um editor rico possa montar a própria moldura e
/// pendurar um controle na linha do rótulo ([headerTrailing]) — o toggle
/// `PX`/`%`, por exemplo, precisa ficar lá e compartilha estado com o corpo.
class PropFieldShell extends StatelessWidget {
  const PropFieldShell({
    required this.label,
    required this.body,
    this.isRequired = false,
    this.headerTrailing,
    this.actions = const [],
    super.key,
  });

  final String label;
  final Widget body;
  final bool isRequired;
  final Widget? headerTrailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.md,
                  color: colors.inkSecondary,
                ),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: AppTheme.primary)),
              const Spacer(),
              ?headerTrailing,
              ...actions,
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          body,
        ],
      ),
    );
  }
}
