import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/editor_colors.dart';

class AlignmentEditor extends StatelessWidget {
  const AlignmentEditor({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
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
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: value == alignment
                            ? colors.primaryTint
                            : colors.panel,
                        border: Border.all(
                          color: value == alignment
                              ? AppTheme.primary
                              : colors.border,
                        ),
                        borderRadius: BorderRadius.circular(4),
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
