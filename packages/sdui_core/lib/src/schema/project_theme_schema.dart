import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/project_theme.dart';
import 'package:sdui_core/src/model/theme_color_role.dart';
import 'package:sdui_core/src/model/theme_radius_step.dart';
import 'package:sdui_core/src/model/theme_shadow.dart';
import 'package:sdui_core/src/model/theme_shadow_level.dart';
import 'package:sdui_core/src/model/theme_text_style.dart';
import 'package:sdui_core/src/model/theme_text_style_name.dart';
import 'package:sdui_core/src/schema/project_theme_item_schemas.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';

const _topKeys = ['colors', 'textStyles', 'radii', 'shadows'];

Either<SpecValidationError, ProjectTheme> parseProjectTheme(
  Map<String, dynamic> json,
) {
  for (final key in json.keys) {
    if (!_topKeys.contains(key)) {
      return Left(SpecValidationError('tema: chave desconhecida "$key"'));
    }
  }
  for (final key in _topKeys) {
    if (!json.containsKey(key)) {
      return Left(SpecValidationError('tema: falta a chave "$key"'));
    }
  }

  return _parseColors(json['colors']).flatMap(
    (colors) => _parseTextStyles(json['textStyles']).flatMap(
      (textStyles) => _parseRadii(json['radii']).flatMap(
        (radii) => _parseShadows(json['shadows']).map(
          (shadows) => ProjectTheme(
            colors: colors,
            textStyles: textStyles,
            radii: radii,
            shadows: shadows,
          ),
        ),
      ),
    ),
  );
}

Either<SpecValidationError, Map<ThemeColorRole, String>> _parseColors(
  Object? raw,
) => _parseGroup(
  raw,
  group: 'colors',
  noun: 'papel',
  values: ThemeColorRole.values,
  parseValue: validateThemeColor,
);

Either<SpecValidationError, Map<ThemeTextStyleName, ThemeTextStyle>>
_parseTextStyles(Object? raw) => _parseGroup(
  raw,
  group: 'textStyles',
  noun: 'estilo',
  values: ThemeTextStyleName.values,
  parseValue: validateThemeTextStyle,
);

Either<SpecValidationError, Map<ThemeRadiusStep, double>> _parseRadii(
  Object? raw,
) => _parseGroup(
  raw,
  group: 'radii',
  noun: 'passo',
  values: ThemeRadiusStep.values,
  parseValue: validateThemeRadius,
);

Either<SpecValidationError, Map<ThemeShadowLevel, ThemeShadow>> _parseShadows(
  Object? raw,
) => _parseGroup(
  raw,
  group: 'shadows',
  noun: 'nível',
  values: ThemeShadowLevel.values,
  parseValue: validateThemeShadow,
);

Either<SpecValidationError, Map<T, V>> _parseGroup<T extends Enum, V>(
  Object? raw, {
  required String group,
  required String noun,
  required List<T> values,
  required Either<SpecValidationError, V> Function(Object? raw, String path)
  parseValue,
}) {
  if (raw is! Map) {
    return Left(SpecValidationError('$group: esperado um objeto'));
  }
  final names = values.asNameMap();
  for (final key in raw.keys) {
    if (!names.containsKey(key)) {
      return Left(SpecValidationError('$group: $noun "$key" desconhecido'));
    }
  }

  final parsed = <T, V>{};
  for (final value in values) {
    if (!raw.containsKey(value.name)) {
      return Left(SpecValidationError('$group: falta o $noun "${value.name}"'));
    }
    final result = parseValue(raw[value.name], '$group.${value.name}');
    switch (result) {
      case Left(:final value):
        return Left(value);
      case Right(value: final item):
        parsed[value] = item;
    }
  }
  return Right(parsed);
}
