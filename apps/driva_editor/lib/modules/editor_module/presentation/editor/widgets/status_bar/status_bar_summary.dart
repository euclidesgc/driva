import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class StatusBarSummary extends StatelessWidget {
  const StatusBarSummary({
    required this.errorCount,
    required this.warningCount,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  final int errorCount;
  final int warningCount;
  final bool isExpanded;
  final VoidCallback? onToggle;

  String get _label {
    if (errorCount == 0 && warningCount == 0) return 'Nenhum problema';
    final parts = <String>[
      if (errorCount > 0) '$errorCount ${errorCount == 1 ? 'erro' : 'erros'}',
      if (warningCount > 0)
        '$warningCount ${warningCount == 1 ? 'aviso' : 'avisos'}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final tone = errorCount > 0
        ? colors.danger
        : warningCount > 0
        ? colors.warning
        : colors.success;
    final icon = errorCount > 0
        ? Icons.error_outline
        : warningCount > 0
        ? Icons.warning_amber_outlined
        : Icons.check_circle_outline;

    return Tooltip(
      message: onToggle == null
          ? 'O conteúdo não tem problemas estruturais'
          : (isExpanded ? 'Ocultar a lista' : 'Ver a lista de problemas'),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: AppSpacing.s6),
              Text(
                _label,
                style: TextStyle(fontSize: AppTypography.sm, color: tone),
              ),
              if (onToggle != null) ...[
                const SizedBox(width: AppSpacing.s4),
                Icon(
                  isExpanded ? Icons.expand_more : Icons.expand_less,
                  size: 14,
                  color: colors.inkMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
