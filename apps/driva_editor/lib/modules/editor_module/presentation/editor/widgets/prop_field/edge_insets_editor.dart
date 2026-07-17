import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/edge_insets_side_field.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

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

  late final Map<String, TextEditingController> _controllers = {
    for (final side in _sides)
      side: TextEditingController(text: _side(side)?.toString() ?? ''),
  };

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
  }

  void _update(String key, double? side) {
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

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EdgeInsetsSideField(
          controller: _controllers['left'],
          label: 'E',
          onChanged: (text) => _update('left', _parse(text)),
        ),
        const SizedBox(width: AppSpacing.s4),
        EdgeInsetsSideField(
          controller: _controllers['top'],
          label: 'T',
          onChanged: (text) => _update('top', _parse(text)),
        ),
        const SizedBox(width: AppSpacing.s4),
        EdgeInsetsSideField(
          controller: _controllers['right'],
          label: 'D',
          onChanged: (text) => _update('right', _parse(text)),
        ),
        const SizedBox(width: AppSpacing.s4),
        EdgeInsetsSideField(
          controller: _controllers['bottom'],
          label: 'B',
          onChanged: (text) => _update('bottom', _parse(text)),
        ),
      ],
    );
  }
}
