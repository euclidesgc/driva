import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// As nove posições canônicas. A célula acende por comparação exata com o par
/// atual: um X fora de -1..1 não acende nenhuma, que é o comportamento do
/// FlutterFlow quando o valor é digitado à mão.
class AlignmentGrid extends StatelessWidget {
  const AlignmentGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ({double x, double y})? selected;
  final void Function(double x, double y) onSelected;

  static const _rows = [
    ['topLeft', 'topCenter', 'topRight'],
    ['centerLeft', 'center', 'centerRight'],
    ['bottomLeft', 'bottomCenter', 'bottomRight'],
  ];

  static List<String> get cellLabels => _labels.values.toList();

  static const _labels = {
    'topLeft': 'Superior esquerdo',
    'topCenter': 'Superior centro',
    'topRight': 'Superior direito',
    'centerLeft': 'Meio esquerdo',
    'center': 'Centro',
    'centerRight': 'Meio direito',
    'bottomLeft': 'Inferior esquerdo',
    'bottomCenter': 'Inferior centro',
    'bottomRight': 'Inferior direito',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in row)
                _AlignmentCell(
                  label: _labels[name]!,
                  position: AlignmentValue.presets[name]!,
                  isSelected: selected == AlignmentValue.presets[name],
                  onPressed: onSelected,
                ),
            ],
          ),
      ],
    );
  }
}

class _AlignmentCell extends StatelessWidget {
  const _AlignmentCell({
    required this.label,
    required this.position,
    required this.isSelected,
    required this.onPressed,
  });

  static const _size = 26.0;
  static const _dotSize = 8.0;

  final String label;
  final ({double x, double y}) position;
  final bool isSelected;
  final void Function(double x, double y) onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () => onPressed(position.x, position.y),
          child: Container(
            width: _size,
            height: _size,
            margin: const EdgeInsets.all(AppSpacing.s1),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryTint : colors.panel,
              border: Border.all(
                color: isSelected ? AppTheme.primary : colors.border,
              ),
              borderRadius: BorderRadius.circular(AppRadii.r4),
            ),
            child: Icon(
              Icons.circle,
              size: _dotSize,
              color: isSelected ? AppTheme.primary : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
