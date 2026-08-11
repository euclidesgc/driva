import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/edge_insets_mode_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/edge_insets_side_field.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Dois modos, como no FlutterFlow: **uniforme** grava `{all: X}` e mostra um
/// campo só; **individual** grava os lados presentes e mostra os quatro.
class EdgeInsetsEditor extends StatefulWidget {
  const EdgeInsetsEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<EdgeInsetsEditor> createState() => _EdgeInsetsEditorState();
}

class _EdgeInsetsEditorState extends State<EdgeInsetsEditor> {
  static const _sides = ['left', 'top', 'right', 'bottom'];
  static const _sideLabels = {
    'left': 'E',
    'top': 'T',
    'right': 'D',
    'bottom': 'B',
  };

  late bool _isUniform = _readsAsUniform(widget.value);

  late final Map<String, TextEditingController> _controllers = {
    for (final side in _sides)
      side: TextEditingController(text: _side(side)?.toString() ?? ''),
  };

  late final TextEditingController _uniformController = TextEditingController(
    text: _uniformValue()?.toString() ?? '',
  );

  static bool _readsAsUniform(Object? value) {
    if (value is! Map) return true;
    if (value.containsKey('all')) return true;
    final sides = {
      for (final side in _sides) (value[side] as num?)?.toDouble(),
    };
    return sides.length == 1;
  }

  double? _uniformValue() {
    final map = widget.value;
    if (map is! Map) return null;
    if (map.containsKey('all')) return (map['all'] as num?)?.toDouble();
    final distinct = {
      for (final side in _sides) (map[side] as num?)?.toDouble(),
    };
    return distinct.length == 1 ? distinct.first : null;
  }

  double? _side(String key) {
    final map = widget.value;
    if (map is! Map) return null;
    if (map.containsKey('all')) return (map['all'] as num?)?.toDouble();
    return (map[key] as num?)?.toDouble();
  }

  double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void didUpdateWidget(covariant EdgeInsetsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    for (final side in _sides) {
      final external = _side(side);
      if (external != _parse(_controllers[side]!.text)) {
        _controllers[side]!.text = external?.toString() ?? '';
      }
    }
    final uniform = _uniformValue();
    if (uniform != _parse(_uniformController.text)) {
      _uniformController.text = uniform?.toString() ?? '';
    }
  }

  void _updateSide(String key, double? side) {
    final current = {for (final s in _sides) s: _side(s), key: side};
    if (current.values.every((v) => v == null)) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged({
      for (final entry in current.entries)
        if (entry.value != null) entry.key: entry.value,
    });
  }

  void _updateUniform(double? all) {
    widget.onChanged(all == null ? null : {'all': all});
  }

  void _changeMode({required bool isUniform}) {
    if (isUniform == _isUniform) return;
    setState(() => _isUniform = isUniform);
    if (isUniform) {
      _updateUniform(_uniformValue() ?? _side('top'));
      return;
    }
    final all = _uniformValue();
    if (all == null) return;
    widget.onChanged({for (final side in _sides) side: all});
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _uniformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EdgeInsetsModeBar(
          isUniform: _isUniform,
          onChanged: (isUniform) => _changeMode(isUniform: isUniform),
        ),
        const SizedBox(height: AppSpacing.s4),
        if (_isUniform)
          Row(
            children: [
              EdgeInsetsSideField(
                controller: _uniformController,
                label: 'Todos',
                onChanged: (text) => _updateUniform(_parse(text)),
              ),
            ],
          )
        else
          Row(
            children: [
              for (final side in _sides) ...[
                if (side != _sides.first) const SizedBox(width: AppSpacing.s4),
                EdgeInsetsSideField(
                  controller: _controllers[side],
                  label: _sideLabels[side]!,
                  onChanged: (text) => _updateSide(side, _parse(text)),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
