import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/default_project_theme.dart';
import 'package:sdui_core/src/model/project_theme.dart';
import 'package:sdui_core/src/model/theme_color_role.dart';
import 'package:sdui_core/src/model/theme_radius_step.dart';
import 'package:sdui_core/src/model/theme_shadow_level.dart';
import 'package:sdui_core/src/model/theme_text_style_name.dart';
import 'package:sdui_core/src/schema/project_theme_item_schemas.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';

ProjectTheme parseProjectThemeTolerant(Object? json) {
  if (json is! Map) return kDefaultProjectTheme;
  return ProjectTheme(
    colors: _readGroup(
      json['colors'],
      ThemeColorRole.values,
      kDefaultProjectTheme.colors,
      validateThemeColor,
    ),
    textStyles: _readGroup(
      json['textStyles'],
      ThemeTextStyleName.values,
      kDefaultProjectTheme.textStyles,
      validateThemeTextStyle,
    ),
    radii: _readGroup(
      json['radii'],
      ThemeRadiusStep.values,
      kDefaultProjectTheme.radii,
      validateThemeRadius,
    ),
    shadows: _readGroup(
      json['shadows'],
      ThemeShadowLevel.values,
      kDefaultProjectTheme.shadows,
      validateThemeShadow,
    ),
  );
}

Map<T, V> _readGroup<T extends Enum, V>(
  Object? raw,
  List<T> values,
  Map<T, V> defaults,
  Either<SpecValidationError, V> Function(Object? raw, String path) validate,
) {
  if (raw is! Map) return defaults;
  return {
    for (final value in values)
      value: validate(
        raw[value.name],
        value.name,
      ).getOrElse((_) => defaults[value] as V),
  };
}
