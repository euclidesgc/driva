import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Com a propriedade ligada a uma variável, o editor por tipo dá lugar a esta
/// faixa: o valor deixou de ser fixo, então não há o que editar aqui — só a
/// expressão, e o caminho de volta ao valor fixo.
class PropBindingEditor extends StatelessWidget {
  const PropBindingEditor({
    required this.expression,
    required this.onClear,
    super.key,
  });

  static const _iconSize = 14.0;

  final String expression;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: colors.primaryTint,
        border: Border.all(color: AppTheme.primary),
        borderRadius: BorderRadius.circular(AppRadii.r6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.data_object,
            size: _iconSize,
            color: AppTheme.primary,
          ),
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Text(
              expression,
              style: const TextStyle(
                fontSize: AppTypography.sm,
                color: AppTheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: 'Voltar a valor fixo',
            child: Semantics(
              button: true,
              label: 'Voltar a valor fixo',
              child: InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(AppRadii.r4),
                child: const Icon(
                  Icons.link_off,
                  size: _iconSize,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
