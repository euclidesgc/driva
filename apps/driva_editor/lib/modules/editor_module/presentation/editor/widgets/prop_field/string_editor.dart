import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class StringEditor extends StatefulWidget {
  const StringEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
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
      style: const TextStyle(fontSize: AppTypography.base),
      decoration: const InputDecoration(isDense: true),
      onChanged: (text) => widget.onChanged(
        text.isEmpty && !widget.field.isRequired ? null : text,
      ),
    );
  }
}
