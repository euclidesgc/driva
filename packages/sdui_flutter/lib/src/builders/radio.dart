import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Preview estático: `selected` vem das props e a interação não muta estado
/// real (o editor desenha design, não formulário funcional). O [RadioGroup]
/// ancestral é o que a API pede desde o 3.32 para fixar o valor do grupo.
Widget buildRadio(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final selected = p['selected'] as bool? ?? false;
  final enabled = p['enabled'] as bool? ?? true;
  final activeColor = parseColor(p['activeColor']);
  final label = (p['label'] as String?)?.trim();

  return RadioGroup<bool>(
    groupValue: selected,
    onChanged: (_) {},
    child: label == null || label.isEmpty
        ? Radio<bool>(value: true, enabled: enabled, activeColor: activeColor)
        : RadioListTile<bool>(
            value: true,
            enabled: enabled,
            activeColor: activeColor,
            title: Text(label),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
  );
}
