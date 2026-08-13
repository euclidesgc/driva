import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Etiqueta que segue o cursor ao arrastar um nó do canvas. Carrega só o rótulo
/// — reaproveitar o widget desenhado deixaria a mesma instância montada duas
/// vezes (no overlay e na árvore).
class NodeDragFeedback extends StatelessWidget {
  const NodeDragFeedback({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.r6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.xs,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
