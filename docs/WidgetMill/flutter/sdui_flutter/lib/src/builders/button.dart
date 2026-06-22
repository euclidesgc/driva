import 'package:flutter/material.dart';
import '../model/sdui_node.dart';
import '../parsing/material_icons.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Estilo do botão — espelha `ButtonStyleProps` do kernel.
ButtonStyle? _styleFrom(Object? raw) {
  if (raw is! Map) return null;
  final m = raw.cast<String, dynamic>();

  final br = parseBorderRadius(m['borderRadius']);
  final sideRaw = m['side'];
  BorderSide? side;
  if (sideRaw is Map) {
    final s = sideRaw.cast<String, dynamic>();
    if (s['style'] != 'none') {
      side = BorderSide(
        color: parseColor(s['color']) ?? const Color(0xFF000000),
        width: (s['width'] as num?)?.toDouble() ?? 1.0,
      );
    }
  }

  return ElevatedButton.styleFrom(
    backgroundColor: parseColor(m['backgroundColor']),
    foregroundColor: parseColor(m['foregroundColor']),
    padding: parseEdgeInsets(m['padding']),
    elevation: (m['elevation'] as num?)?.toDouble(),
    textStyle: parseTextStyle(m['textStyle']),
    side: side,
    shape: br != null ? RoundedRectangleBorder(borderRadius: br) : null,
  );
}

/// Button — spec §2.8. Variantes + estilo + ícone opcional (`*.icon(...)`).
Widget buildButton(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  final enabled = p['enabled'] as bool? ?? true;
  final onPressed = enabled ? () => r.dispatch(p['onPressed']) : null;
  final style = _styleFrom(p['style']);
  final label =
      r.maybeRender(context, node.child) ?? Text((p['label'] ?? '').toString());

  final iconName = p['icon'];
  final icon = (iconName is String && iconName.isNotEmpty)
      ? Icon(iconDataFrom(iconName))
      : null;

  if (icon != null) {
    return switch (p['variant']) {
      'text' =>
        TextButton.icon(onPressed: onPressed, style: style, icon: icon, label: label),
      'outlined' => OutlinedButton.icon(
          onPressed: onPressed, style: style, icon: icon, label: label),
      'filled' => FilledButton.icon(
          onPressed: onPressed, style: style, icon: icon, label: label),
      _ => ElevatedButton.icon(
          onPressed: onPressed, style: style, icon: icon, label: label),
    };
  }

  return switch (p['variant']) {
    'text' => TextButton(onPressed: onPressed, style: style, child: label),
    'outlined' =>
      OutlinedButton(onPressed: onPressed, style: style, child: label),
    'filled' => FilledButton(onPressed: onPressed, style: style, child: label),
    _ => ElevatedButton(onPressed: onPressed, style: style, child: label),
  };
}
