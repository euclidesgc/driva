import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/project_theme.dart';
import 'package:sdui_core/src/model/theme_color_role.dart';
import 'package:sdui_core/src/model/theme_radius_step.dart';
import 'package:sdui_core/src/model/theme_shadow.dart';
import 'package:sdui_core/src/model/theme_shadow_level.dart';
import 'package:sdui_core/src/model/theme_text_style.dart';
import 'package:sdui_core/src/model/theme_text_style_name.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:zard/zard.dart';

const _topKeys = ['colors', 'textStyles', 'radii', 'shadows'];

const _fontWeights = [
  'w100',
  'w200',
  'w300',
  'w400',
  'w500',
  'w600',
  'w700',
  'w800',
  'w900',
];

const _hexMessage = 'esperado #RRGGBB ou #AARRGGBB';

final ZString _hexColor = z.string().regex(
  RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$'),
  message: _hexMessage,
);

ZNum _number() => z.num(message: 'esperado um número');

final ZMap _textStyle = z.map({
  'fontSize': _number().positive(message: 'esperado um número maior que 0'),
  'fontWeight': z.$enum(
    _fontWeights,
    message: 'esperado um de ${_fontWeights.join(', ')}',
  ),
  'lineHeight': _number(),
  'letterSpacing': _number(),
  'fontFamily': z.string().min(1).optional(),
});

final ZNum _radius = _number().nonnegative(
  message: 'esperado um número maior ou igual a 0',
);

final ZMap _shadow = z.map({
  'color': _hexColor,
  'offsetX': _number(),
  'offsetY': _number(),
  'blur': _number().nonnegative(
    message: 'esperado um número maior ou igual a 0',
  ),
  'spread': _number(),
});

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
  parseValue: (value, path) =>
      _validate(_hexColor, value, path).map((data) => data! as String),
);

Either<SpecValidationError, Map<ThemeTextStyleName, ThemeTextStyle>>
_parseTextStyles(Object? raw) => _parseGroup(
  raw,
  group: 'textStyles',
  noun: 'estilo',
  values: ThemeTextStyleName.values,
  parseValue: (value, path) =>
      _validate(_textStyle, value, path).map(_toTextStyle),
);

Either<SpecValidationError, Map<ThemeRadiusStep, double>> _parseRadii(
  Object? raw,
) => _parseGroup(
  raw,
  group: 'radii',
  noun: 'passo',
  values: ThemeRadiusStep.values,
  parseValue: (value, path) => _validate(
    _radius,
    value,
    path,
  ).map((data) => (data! as num).toDouble()),
);

Either<SpecValidationError, Map<ThemeShadowLevel, ThemeShadow>> _parseShadows(
  Object? raw,
) => _parseGroup(
  raw,
  group: 'shadows',
  noun: 'nível',
  values: ThemeShadowLevel.values,
  parseValue: (value, path) => _validate(_shadow, value, path).map(_toShadow),
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

Either<SpecValidationError, Object?> _validate(
  Schema<Object?> schema,
  Object? raw,
  String path,
) {
  if (schema is ZMap && raw is! Map) {
    return Left(SpecValidationError('$path: esperado um objeto'));
  }
  final result = schema.safeParse(raw);
  if (result.success) return Right(result.data);

  final issue = result.error!.issues.first;
  final where = issue.path == null || issue.path!.isEmpty
      ? path
      : '$path.${issue.path}';
  return Left(SpecValidationError('$where: ${issue.message}'));
}

ThemeTextStyle _toTextStyle(Object? data) {
  final map = data! as Map;
  return ThemeTextStyle(
    fontSize: (map['fontSize'] as num).toDouble(),
    fontWeight: map['fontWeight'] as String,
    lineHeight: (map['lineHeight'] as num).toDouble(),
    letterSpacing: (map['letterSpacing'] as num).toDouble(),
    fontFamily: map['fontFamily'] as String?,
  );
}

ThemeShadow _toShadow(Object? data) {
  final map = data! as Map;
  return ThemeShadow(
    color: map['color'] as String,
    offsetX: (map['offsetX'] as num).toDouble(),
    offsetY: (map['offsetY'] as num).toDouble(),
    blur: (map['blur'] as num).toDouble(),
    spread: (map['spread'] as num).toDouble(),
  );
}
