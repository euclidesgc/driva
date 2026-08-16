import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Cabeçalho de grupo colapsável, genérico o bastante para servir a paleta e,
/// no futuro, o painel JSON (item 8b — terceiro cliente): rótulo, indicador à
/// direita, estado e alternância vêm todos por fora.
///
/// `onToggle` nulo desliga a interatividade (busca ativa forçando o grupo
/// aberto): o cabeçalho vira informativo — sem `InkWell`, sem tooltip, sem
/// semântica de botão — porque um clique ali não teria efeito visível
/// nenhum, e prometer ação onde não há é a mesma surpresa que o aceite 22
/// existe para evitar, só que do outro lado.
class PaletteCategoryHeader extends StatelessWidget {
  const PaletteCategoryHeader({
    required this.label,
    required this.isExpanded,
    this.onToggle,
    this.trailing,
    super.key,
  });

  final String label;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Icon(
            isExpanded ? Icons.expand_more : Icons.chevron_right,
            size: AppIconSizes.s18,
            color: colors.inkMuted,
          ),
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  fontWeight: FontWeight.w600,
                  color: colors.inkMuted,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );

    final onToggle = this.onToggle;
    if (onToggle == null) {
      return Semantics(label: label, child: content);
    }

    final actionHint = isExpanded ? 'Recolher' : 'Expandir';
    return Tooltip(
      message: '$actionHint $label',
      child: Semantics(
        button: true,
        expanded: isExpanded,
        label: label,
        hint: actionHint,
        child: InkWell(onTap: onToggle, child: content),
      ),
    );
  }
}
