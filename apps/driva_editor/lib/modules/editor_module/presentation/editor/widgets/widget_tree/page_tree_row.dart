import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Topo fixo da árvore: a própria página. Não é um nó do documento — existe
/// para dar onde clicar e editar a área segura, que embrulha toda página.
class PageTreeRow extends StatelessWidget {
  const PageTreeRow({
    required this.isSelected,
    required this.onSelect,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Semantics(
      selected: isSelected,
      label: 'Página',
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryTint : null,
            border: Border(
              left: BorderSide(
                width: 3,
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_iphone_outlined,
                size: 16,
                color: isSelected ? AppTheme.primary : colors.inkSecondary,
              ),
              const SizedBox(width: AppSpacing.s8),
              const Expanded(
                child: Text(
                  'Página · área segura',
                  style: TextStyle(fontSize: AppTypography.base),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
