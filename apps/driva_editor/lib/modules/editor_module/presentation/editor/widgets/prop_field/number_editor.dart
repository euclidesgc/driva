import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class NumberEditor extends StatefulWidget {
  const NumberEditor({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.isInt,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool isInt;

  @override
  State<NumberEditor> createState() => _NumberEditorState();
}

class _NumberEditorState extends State<NumberEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  num? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return widget.isInt
        ? int.tryParse(trimmed)
        : double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void didUpdateWidget(covariant NumberEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ressincroniza só em mudança externa e quando o número realmente difere:
    // comparar por texto recolocaria o cursor no meio de "1." → "1.0".
    if (widget.value != oldWidget.value &&
        widget.value != _parse(_controller.text)) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(isDense: true, hintText: '—'),
      onChanged: (text) {
        if (text.trim().isEmpty) {
          widget.onChanged(null);
          return;
        }
        final parsed = _parse(text);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}
