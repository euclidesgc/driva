import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class AlignmentEditor extends StatelessWidget {
  const AlignmentEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  static const _grid = [
    ['topLeft', 'topCenter', 'topRight'],
    ['centerLeft', 'center', 'centerRight'],
    ['bottomLeft', 'bottomCenter', 'bottomRight'],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rowValues in _grid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final alignment in rowValues)
                Tooltip(
                  message: alignment,
                  child: InkWell(
                    onTap: () =>
                        onChanged(value == alignment ? null : alignment),
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.all(AppSpacing.s1),
                      decoration: BoxDecoration(
                        color: value == alignment
                            ? colors.primaryTint
                            : colors.panel,
                        border: Border.all(
                          color: value == alignment
                              ? AppTheme.primary
                              : colors.border,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.r4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: value == alignment
                            ? AppTheme.primary
                            : colors.inkMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
