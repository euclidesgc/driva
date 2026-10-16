import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class PropSummaryRow extends StatelessWidget {
  const PropSummaryRow({
    required this.label,
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  final String label;
  final String summary;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Semantics(
      button: true,
      expanded: isExpanded,
      label: label,
      child: SizedBox(
        height: AppSizes.propSummaryRowHeight,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s12,
              right: AppSpacing.s8,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.md,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: AppTypography.xs,
                      color: colors.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.chevron_right,
                  size: AppIconSizes.s18,
                  color: colors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
