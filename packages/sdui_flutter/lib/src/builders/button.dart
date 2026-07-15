import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildButton(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final enabled = p['enabled'] as bool? ?? true;
  final onPressed = enabled ? () => r.dispatch(node.events['onPressed']) : null;

  final borderRadius = parseBorderRadius(p['borderRadius']);
  final fontSize = parseDouble(p['fontSize']);
  final style = ElevatedButton.styleFrom(
    backgroundColor: parseColor(p['backgroundColor']),
    foregroundColor: parseColor(p['foregroundColor']),
    textStyle: fontSize != null ? TextStyle(fontSize: fontSize) : null,
    shape: borderRadius != null
        ? RoundedRectangleBorder(borderRadius: borderRadius)
        : null,
  );
  final label = Text((p['label'] ?? '').toString());

  return switch (p['variant']) {
    'text' => TextButton(onPressed: onPressed, style: style, child: label),
    'outlined' => OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: label,
    ),
    'filled' => FilledButton(onPressed: onPressed, style: style, child: label),
    _ => ElevatedButton(onPressed: onPressed, style: style, child: label),
  };
}
