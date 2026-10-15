import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/theme_shadow.dart';
import 'package:sdui_core/src/model/theme_text_style.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:zard/zard.dart';

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

Either<SpecValidationError, String> validateThemeColor(
  Object? raw,
  String path,
) => _validate(_hexColor, raw, path).map((data) => data! as String);

Either<SpecValidationError, ThemeTextStyle> validateThemeTextStyle(
  Object? raw,
  String path,
) => _validate(_textStyle, raw, path).map(_toTextStyle);

Either<SpecValidationError, double> validateThemeRadius(
  Object? raw,
  String path,
) => _validate(_radius, raw, path).map((data) => (data! as num).toDouble());

Either<SpecValidationError, ThemeShadow> validateThemeShadow(
  Object? raw,
  String path,
) => _validate(_shadow, raw, path).map(_toShadow);

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
