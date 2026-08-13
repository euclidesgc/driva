import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Fresta entre duas linhas da árvore. Invisível em repouso — só a linha de
/// inserção aparece quando um arraste passa por cima.
class TreeGapIndicator extends StatelessWidget {
  const TreeGapIndicator({
    required this.depth,
    required this.isActive,
    super.key,
  });

  final int depth;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.s6,
      padding: EdgeInsets.only(
        left: AppSpacing.s12 + depth * AppSpacing.s16,
        right: AppSpacing.s12,
      ),
      alignment: Alignment.center,
      child: isActive
          ? Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppRadii.r3),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
