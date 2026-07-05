import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../renderer.dart';

/// TextField. Preview estático: o `value` vem das props e não muta estado
/// real (o editor renderiza design, não formulário funcional).
Widget buildTextField(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final label = (p['label'] as String?)?.trim();
  final hint = (p['hint'] as String?)?.trim();
  final helperText = (p['helperText'] as String?)?.trim();
  final value = p['value'] as String?;

  return TextFormField(
    initialValue: value,
    enabled: p['enabled'] as bool? ?? true,
    obscureText: p['obscureText'] as bool? ?? false,
    decoration: InputDecoration(
      labelText: (label?.isEmpty ?? true) ? null : label,
      hintText: (hint?.isEmpty ?? true) ? null : hint,
      helperText: (helperText?.isEmpty ?? true) ? null : helperText,
      filled: p['filled'] as bool? ?? false,
      border: const OutlineInputBorder(),
    ),
  );
}
