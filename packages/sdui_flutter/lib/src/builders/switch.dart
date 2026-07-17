import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Switch. Preview estático: o `value` vem das props; a interação não muta
/// estado real (o editor renderiza design, não formulário funcional). Com
/// `label` vira [SwitchListTile]; sem, um [Switch] simples.
Widget buildSwitch(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final value = p['value'] as bool? ?? false;
  final enabled = p['enabled'] as bool? ?? true;
  final activeColor = parseColor(p['activeColor']);
  final onChanged = enabled ? (_) {} : null;
  final label = (p['label'] as String?)?.trim();

  if (label != null && label.isNotEmpty) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      title: Text(label),
      contentPadding: EdgeInsets.zero,
    );
  }
  return Switch(
    value: value,
    onChanged: onChanged,
    activeThumbColor: activeColor,
  );
}
