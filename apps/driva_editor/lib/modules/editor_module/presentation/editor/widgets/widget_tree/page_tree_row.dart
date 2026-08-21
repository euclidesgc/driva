import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diff_marker.dart';
import 'package:flutter/material.dart';

/// Topo fixo da árvore: a própria página. Não é um nó do documento — existe
/// para dar onde clicar e editar a área segura, que embrulha toda página.
class PageTreeRow extends StatelessWidget {
  const PageTreeRow({
    required this.isSelected,
    required this.onSelect,
    this.diffMarkerKinds = const [],
    super.key,
  });

  final bool isSelected;
  final VoidCallback onSelect;

  /// `safeArea` e metadados do conteúdo não pertencem a nó nenhum — os
  /// marcadores deles moram nesta linha fixa.
  final List<VersionCompareMarkerKind> diffMarkerKinds;

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
              for (final kind in diffMarkerKinds)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s4),
                  child: TreeRowDiffMarker(kind: kind),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
