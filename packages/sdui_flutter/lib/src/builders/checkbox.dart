import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

/// Checkbox. Preview estático: o `value` vem das props; a interação não muta
/// estado real (o editor renderiza design, não formulário funcional). Com
/// `label` vira [CheckboxListTile]; sem, um [Checkbox] simples.
Widget buildCheckbox(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final value = p['value'] as bool? ?? false;
  final enabled = p['enabled'] as bool? ?? true;
  final activeColor = parseColor(p['activeColor']);
  final onChanged = enabled ? (bool? _) {} : null;
  final label = (p['label'] as String?)?.trim();

  if (label != null && label.isNotEmpty) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
  return Checkbox(value: value, onChanged: onChanged, activeColor: activeColor);
}
