import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:flutter/material.dart';

class AppShellStatusIndicator extends StatelessWidget {
  const AppShellStatusIndicator({
    required this.status,
    this.flexible = true,
    super.key,
  });

  final AppBarStatus status;

  /// `false` remove o `Flexible` interno, tornando o indicador **mensurável
  /// sem teto de largura**: com ele, medir esta linha sem restrição é erro de
  /// layout, e o resultado vem zerado. Quem precisa disso é o medidor da
  /// barra do topo, que decide o colapso pelo tamanho real do conteúdo.
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status.tone) {
      AppBarStatusTone.success => Theme.of(
        context,
      ).extension<EditorColors>()!.success,
      AppBarStatusTone.neutral => scheme.onSurfaceVariant,
      AppBarStatusTone.danger => scheme.error,
    };
    return Semantics(
      liveRegion: true,
      label: 'Status: ${status.label}',
      child: Tooltip(
        message: status.label,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: AppIconSizes.s16, color: color),
            const SizedBox(width: AppSpacing.s4),
            if (flexible)
              Flexible(
                child: Text(
                  status.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: color, fontSize: AppTypography.base),
                ),
              )
            else
              Text(
                status.label,
                maxLines: 1,
                style: TextStyle(color: color, fontSize: AppTypography.base),
              ),
          ],
        ),
      ),
    );
  }
}
