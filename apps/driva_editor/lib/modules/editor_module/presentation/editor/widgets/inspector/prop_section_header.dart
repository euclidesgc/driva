import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class PropSectionHeader extends StatelessWidget {
  const PropSectionHeader({
    required this.label,
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  static const _chevronSize = 18.0;

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
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s12,
            AppSpacing.s10,
            AppSpacing.s8,
            AppSpacing.s10,
          ),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: AppTypography.xs,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: colors.inkMuted,
                ),
              ),
              const Spacer(),
              if (!isExpanded)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s4),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: AppTypography.xs,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.chevron_right,
                size: _chevronSize,
                color: colors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
