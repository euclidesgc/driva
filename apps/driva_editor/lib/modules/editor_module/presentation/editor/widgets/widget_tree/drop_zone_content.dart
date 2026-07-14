import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/editor_colors.dart';

/// Corpo do `builder:` do [DragTarget] da zona de soltar: a moldura com o
/// rótulo, realçada quando há um item sobre ela ([isDragOver] deriva de
/// `candidates.isNotEmpty`).
class DropZoneContent extends StatelessWidget {
  const DropZoneContent({
    super.key,
    required this.isDragOver,
    required this.label,
  });

  final bool isDragOver;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final active = isDragOver;
    return Container(
      margin: const EdgeInsets.all(12),
      height: 44,
      decoration: BoxDecoration(
        color: active ? colors.primaryTint : null,
        border: Border.all(
          color: active ? AppTheme.primary : colors.border,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? AppTheme.primary : colors.inkMuted,
          ),
        ),
      ),
    );
  }
}
