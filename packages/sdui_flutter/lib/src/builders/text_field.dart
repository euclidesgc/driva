import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/material_icons.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// TextField. Preview estático: o `value` vem das props e não muta estado
/// real (o editor renderiza design, não formulário funcional).
Widget buildTextField(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final label = (p['label'] as String?)?.trim();
  final hint = (p['hint'] as String?)?.trim();
  final helperText = (p['helperText'] as String?)?.trim();
  final value = p['value'] as String?;
  final borderStyle = p['borderStyle'] as String? ?? 'outline';
  final prefixIcon = p['prefixIcon'];

  final (border, filled) = switch (borderStyle) {
    'underline' => (const UnderlineInputBorder(), false),
    'filled' => (const OutlineInputBorder(borderSide: BorderSide.none), true),
    _ => (const OutlineInputBorder(), false),
  };

  return TextFormField(
    initialValue: value,
    enabled: p['enabled'] as bool? ?? true,
    obscureText: p['obscureText'] as bool? ?? false,
    keyboardType: _keyboardTypeFrom(p['keyboardType']),
    maxLength: parseInt(p['maxLength']),
    decoration: InputDecoration(
      labelText: (label?.isEmpty ?? true) ? null : label,
      hintText: (hint?.isEmpty ?? true) ? null : hint,
      helperText: (helperText?.isEmpty ?? true) ? null : helperText,
      prefixIcon: prefixIcon == null ? null : Icon(iconDataFrom(prefixIcon)),
      filled: filled,
      border: border,
    ),
  );
}

TextInputType? _keyboardTypeFrom(Object? value) => switch (value) {
  'number' => TextInputType.number,
  'email' => TextInputType.emailAddress,
  'phone' => TextInputType.phone,
  'url' => TextInputType.url,
  'text' => TextInputType.text,
  _ => null,
};
