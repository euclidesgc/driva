import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class StringEditor extends StatefulWidget {
  const StringEditor({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<StringEditor> createState() => _StringEditorState();
}

class _StringEditorState extends State<StringEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void didUpdateWidget(covariant StringEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final external = widget.value?.toString() ?? '';
    if (widget.value != oldWidget.value && external != _controller.text) {
      _controller.text = external;
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
      decoration: const InputDecoration(isDense: true),
      onChanged: (text) => widget.onChanged(
        text.isEmpty && !widget.field.isRequired ? null : text,
      ),
    );
  }
}
