import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Preview estático: o valor vem das props e é clampado na faixa, para uma
/// faixa mal preenchida no editor não derrubar o canvas.
Widget buildSlider(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final min = parseDouble(p['min']) ?? 0;
  final max = parseDouble(p['max']) ?? 100;
  final safeMax = max > min ? max : min + 1;
  final value = (parseDouble(p['value']) ?? min).clamp(min, safeMax);
  final divisions = parseInt(p['divisions']);
  final enabled = p['enabled'] as bool? ?? true;

  return Slider(
    value: value,
    min: min,
    max: safeMax,
    divisions: divisions != null && divisions > 0 ? divisions : null,
    label: p['showLabel'] as bool? ?? false ? value.toString() : null,
    activeColor: parseColor(p['activeColor']),
    onChanged: enabled ? (_) {} : null,
  );
}
