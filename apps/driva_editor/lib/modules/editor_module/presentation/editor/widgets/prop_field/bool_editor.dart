import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class BoolEditor extends StatelessWidget {
  const BoolEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value is bool
        ? value! as bool
        : (field.defaultValue as bool? ?? false);
    return Align(
      alignment: Alignment.centerLeft,
      child: Switch(value: current, onChanged: onChanged),
    );
  }
}
