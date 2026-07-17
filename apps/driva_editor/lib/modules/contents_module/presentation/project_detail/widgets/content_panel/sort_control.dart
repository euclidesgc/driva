import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_sort.dart';
import 'package:flutter/material.dart';

class SortControl extends StatelessWidget {
  const SortControl({
    required this.sort,
    required this.order,
    required this.onSortChanged,
    required this.onToggleOrder,
    super.key,
  });

  final ContentSort sort;
  final ContentSortOrder order;
  final ValueChanged<ContentSort> onSortChanged;
  final VoidCallback onToggleOrder;

  static String _label(ContentSort sort) => switch (sort) {
    ContentSort.updatedAt => 'Atualização',
    ContentSort.createdAt => 'Criação',
    ContentSort.name => 'Nome',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final isDesc = order == ContentSortOrder.desc;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadii.r9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Ordenar por',
            child: PopupMenuButton<ContentSort>(
              initialValue: sort,
              onSelected: onSortChanged,
              tooltip: '',
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                for (final option in ContentSort.values)
                  CheckedPopupMenuItem<ContentSort>(
                    value: option,
                    checked: option == sort,
                    child: Text(_label(option)),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: colors.inkMuted),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      _label(sort),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: colors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Tooltip(
            message: isDesc ? 'Decrescente' : 'Crescente',
            child: Semantics(
              button: true,
              label:
                  'Direção da ordenação: '
                  '${isDesc ? 'decrescente' : 'crescente'}',
              child: InkWell(
                onTap: onToggleOrder,
                borderRadius: BorderRadius.circular(AppRadii.r6),
                child: Container(
                  width: 30,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(
                    isDesc ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
