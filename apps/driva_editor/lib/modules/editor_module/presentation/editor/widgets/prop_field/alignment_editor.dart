import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/alignment_axis_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/alignment_grid.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/numeric_clamp.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Grade de nove posições e os eixos X/Y lado a lado, como no FlutterFlow —
/// duas vistas do mesmo valor.
///
/// O par `(x, y)` é a verdade interna; a emissão passa por
/// [AlignmentValue.encode], que prefere o nome do preset. Sem esse ponto único,
/// clicar numa célula depois de digitar um X livre deixaria os dois controles
/// contando histórias diferentes.
class AlignmentEditor extends StatefulWidget {
  const AlignmentEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<AlignmentEditor> createState() => _AlignmentEditorState();
}

class _AlignmentEditorState extends State<AlignmentEditor> {
  late final TextEditingController _x = TextEditingController(
    text: _textOf(_pair?.x),
  );
  late final TextEditingController _y = TextEditingController(
    text: _textOf(_pair?.y),
  );

  ({double x, double y})? get _pair => AlignmentValue.parse(widget.value);

  static String _textOf(double? axis) => axis == null ? '' : formatNumber(axis);

  static double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void didUpdateWidget(covariant AlignmentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    final pair = _pair;
    // Comparar pelo valor, não pelo texto: comparar texto moveria o cursor.
    if (_parse(_x.text) != pair?.x) _x.text = _textOf(pair?.x);
    if (_parse(_y.text) != pair?.y) _y.text = _textOf(pair?.y);
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  void _emitAxes() {
    final x = _parse(_x.text);
    final y = _parse(_y.text);
    if (x == null && y == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(AlignmentValue.encode(x: x ?? 0, y: y ?? 0));
  }

  void _selectCell(double x, double y) {
    final isSelected = _pair?.x == x && _pair?.y == y;
    if (isSelected && !widget.field.isRequired) {
      _x.clear();
      _y.clear();
      widget.onChanged(null);
      return;
    }
    _x.text = _textOf(x);
    _y.text = _textOf(y);
    widget.onChanged(AlignmentValue.encode(x: x, y: y));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              AlignmentAxisField(
                label: 'X',
                controller: _x,
                onChanged: (_) => _emitAxes(),
              ),
              const SizedBox(height: AppSpacing.s4),
              AlignmentAxisField(
                label: 'Y',
                controller: _y,
                onChanged: (_) => _emitAxes(),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        AlignmentGrid(selected: _pair, onSelected: _selectCell),
      ],
    );
  }
}
