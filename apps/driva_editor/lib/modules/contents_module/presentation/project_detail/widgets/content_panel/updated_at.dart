import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';
import '../../../../../../core/util/date_format.dart';

/// Data da última modificação (`updatedAt`) — ícone de relógio + texto, para
/// que a informação não dependa só da cor. Fonte pequena e discreta; o valor
/// exato (fuso local) aparece formatado e como rótulo de acessibilidade.
class UpdatedAt extends StatelessWidget {
  const UpdatedAt({super.key, required this.updatedAt});

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
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                formatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  fontSize: 11,
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
