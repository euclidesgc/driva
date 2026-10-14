import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_source_ids.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_binding.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:zard/zard.dart';

final ZString _themeToken = z.string().min(1);

// O zard não tem `z.any`: os três literais de `$bind` aceitam qualquer JSON e
// são conferidos à mão, como o parseNode faz com `props`/`events`.
final ZMap _bindScalars = z.map({
  'source': z.string().min(1),
  'path': z.string().min(1),
  'transform': z.string().min(1).optional(),
});

const _bindLiteralKeys = ['fallback', 'preview', 'literal'];

const Set<String> _bindKeys = {
  'source',
  'path',
  'transform',
  ..._bindLiteralKeys,
};

Either<SpecValidationError, PropValue> parsePropValue(
  Object? raw, {
  String path = 'value',
}) {
  if (!PropValue.isTypedForm(raw)) {
    final expression = SduiBinding.expressionOf(raw);
    return Right(
      expression == null
          ? LiteralPropValue(raw)
          : BoundPropValue.legacy(expression),
    );
  }

  final map = raw! as Map;
  final key = map.containsKey(PropValue.themeKey)
      ? PropValue.themeKey
      : PropValue.bindKey;
  if (map.length > 1) {
    final extra = map.keys.where((k) => k != key).join(', ');
    return Left(
      SpecValidationError('$path: $key não aceita outras chaves ($extra)'),
    );
  }

  return key == PropValue.themeKey
      ? _parseThemeRef(map[key], '$path.$key')
      : _parseBound(map[key], '$path.$key');
}

Either<SpecValidationError, PropValue> _parseThemeRef(
  Object? raw,
  String path,
) {
  final result = _themeToken.safeParse(raw);
  if (!result.success) {
    return Left(
      SpecValidationError('$path: ${z.prettifyError(result.error!)}'),
    );
  }
  return Right(ThemeRefPropValue(result.data!));
}

Either<SpecValidationError, PropValue> _parseBound(Object? raw, String path) {
  if (raw is! Map) {
    return Left(SpecValidationError('$path: esperado um objeto'));
  }
  for (final key in raw.keys) {
    if (!_bindKeys.contains(key)) {
      return Left(SpecValidationError('$path: chave desconhecida "$key"'));
    }
  }

  final json = raw.cast<String, dynamic>();
  final result = _bindScalars.safeParse(json);
  if (!result.success) {
    return Left(
      SpecValidationError('$path: ${z.prettifyError(result.error!)}'),
    );
  }

  for (final key in _bindLiteralKeys) {
    if (!json.containsKey(key)) continue;
    final value = json[key];
    if (value == null || PropValue.isTypedForm(value)) {
      return Left(
        SpecValidationError(
          '$path.$key: esperado um literal JSON '
          '(sem ${PropValue.themeKey}/${PropValue.bindKey} e não nulo)',
        ),
      );
    }
  }

  final source = result.data!['source'] as String;
  if (source == BindingSourceIds.legacy) {
    return Left(
      SpecValidationError(
        '$path.source: fonte "${BindingSourceIds.legacy}" só vale como '
        '{{expressão}}',
      ),
    );
  }

  return Right(
    BoundPropValue(
      source: source,
      path: result.data!['path'] as String,
      transform: result.data!['transform'] as String?,
      fallback: json['fallback'],
      preview: json['preview'],
      literal: json['literal'],
    ),
  );
}
