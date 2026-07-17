import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:flutter/material.dart';

/// Data da última modificação (`updatedAt`) — ícone de relógio + texto, para
/// que a informação não dependa só da cor. Fonte pequena e discreta; o valor
/// exato (fuso local) aparece formatado e como rótulo de acessibilidade.
class UpdatedAt extends StatelessWidget {
  const UpdatedAt({required this.updatedAt, super.key});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(updatedAt);
    return Tooltip(
      message: 'Última modificação',
      child: Semantics(
        label: 'Modificado em $formatted',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12, color: colors.inkMuted),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                formatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  fontSize: AppTypography.sm,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
