import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';

/// Um papel que o tema não conhece (spec de uma versão mais nova, aceito pelo
/// parse tolerante) sai `null`, como uma prop ausente: a página não cai.
Color? resolveColor(Object? raw, ProjectTheme theme) {
  if (raw case {PropValue.themeKey: final String token}) {
    final role = ThemeColorRole.fromName(token);
    return role == null ? null : parseColor(theme.colors[role]);
  }
  return parseColor(raw);
}

TextStyle? resolveThemeTextStyle(String name, ProjectTheme theme) {
  final styleName = ThemeTextStyleName.fromName(name);
  final style = styleName == null ? null : theme.textStyles[styleName];
  if (style == null) return null;
  return TextStyle(
    fontSize: style.fontSize,
    fontWeight: parseFontWeight(style.fontWeight),
    height: style.lineHeight,
    letterSpacing: style.letterSpacing,
    fontFamily: style.fontFamily,
  );
}
