import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter/material.dart';

/// Uma linha do histórico: versão, data, nota (se houver), selo "No ar" e a
/// ação de restaurar para o rascunho.
class VersionRow extends StatelessWidget {
  const VersionRow({
    required this.version,
    required this.isPublished,
    required this.onRestore,
    super.key,
  });

  final ContentVersion version;
  final bool isPublished;
  final ValueChanged<int> onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(version.createdAt);
    final note = version.note;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Versão ${version.version}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPublished) ...[
                      const SizedBox(width: AppSpacing.s8),
                      Icon(
                        Icons.public,
                        size: AppIconSizes.s13,
                        color: colors.success,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        'No ar',
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          color: colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  formatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.inkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          TextButton(
            onPressed: () => onRestore(version.version),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
}
