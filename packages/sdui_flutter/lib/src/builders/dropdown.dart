import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/theme_resolvers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Preview estático: mostra o valor escolhido (ou o hint). A lista de opções
/// é dado do app cliente, não do desenho — o editor só desenha o campo.
Widget buildDropdown(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final value = (p['value'] as String?)?.trim();
  final hint = (p['hint'] as String?)?.trim();
  final label = (p['label'] as String?)?.trim();
  final enabled = p['enabled'] as bool? ?? true;
  final hasValue = value != null && value.isNotEmpty;
  final fillColor = resolveColor(p['fillColor'], r.theme);

  return DropdownButtonFormField<String>(
    initialValue: hasValue ? value : null,
    hint: hint == null || hint.isEmpty ? null : Text(hint),
    decoration: InputDecoration(
      labelText: label == null || label.isEmpty ? null : label,
      border: const OutlineInputBorder(),
      fillColor: fillColor,
      filled: fillColor != null,
    ),
    items: [if (hasValue) DropdownMenuItem(value: value, child: Text(value))],
    onChanged: enabled ? (_) {} : null,
  );
}
