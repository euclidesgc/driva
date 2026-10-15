import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/default_project_theme.dart';
import 'package:sdui_core/src/model/project_theme.dart';
import 'package:sdui_core/src/schema/project_theme_item_schemas.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';

ProjectTheme parseProjectThemeTolerant(Object? json) {
  if (json is! Map) return kDefaultProjectTheme;
  return ProjectTheme(
    colors: _readGroup(
      json['colors'],
      kDefaultProjectTheme.colors,
      validateThemeColor,
    ),
    textStyles: _readGroup(
      json['textStyles'],
      kDefaultProjectTheme.textStyles,
      validateThemeTextStyle,
    ),
    radii: _readGroup(
      json['radii'],
      kDefaultProjectTheme.radii,
      validateThemeRadius,
    ),
    shadows: _readGroup(
      json['shadows'],
      kDefaultProjectTheme.shadows,
      validateThemeShadow,
    ),
  );
}

Map<T, V> _readGroup<T extends Enum, V>(
  Object? raw,
  Map<T, V> defaults,
  Either<SpecValidationError, V> Function(Object? raw, String path) validate,
) {
  if (raw is! Map) return defaults;
  return {
    for (final MapEntry(key: item, value: fallback) in defaults.entries)
      item: validate(raw[item.name], item.name).getOrElse((_) => fallback),
  };
}
