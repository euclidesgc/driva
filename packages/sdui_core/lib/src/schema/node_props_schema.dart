import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/binding_source_catalog.dart';
import 'package:sdui_core/src/catalog/prop_field.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/schema/prop_value_schema.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:sdui_core/src/schema/spec_version.dart';

const _typedForms = '${PropValue.themeKey}/${PropValue.bindKey}';

Either<SpecValidationError, Unit> validateNodeProps(
  Map<String, dynamic> props,
  WidgetDescriptor descriptor, {
  required String path,
  required int specVersion,
  required BindingContext context,
}) => validateFieldValues(
  props,
  descriptor.fields,
  path: path,
  specVersion: specVersion,
  context: context,
);

/// A mesma regra das props para qualquer lista de campos (os parâmetros de
/// uma ação, por exemplo). Só confere as formas tipadas: o literal passa como
/// veio, e chave sem campo é conferida sem regra de campo.
Either<SpecValidationError, Unit> validateFieldValues(
  Map<String, dynamic> values,
  List<PropField> fields, {
  required String path,
  required int specVersion,
  required BindingContext context,
}) {
  for (final MapEntry(:key, :value) in values.entries) {
    if (!PropValue.isTypedForm(value)) continue;
    final result = _validateTypedProp(
      value,
      _fieldOf(fields, key),
      path: '$path.$key',
      specVersion: specVersion,
      context: context,
    );
    if (result.isLeft()) return result;
  }
  return const Right(unit);
}

PropField? _fieldOf(List<PropField> fields, String key) {
  for (final field in fields) {
    if (field.key == key) return field;
  }
  return null;
}

Either<SpecValidationError, Unit> _validateTypedProp(
  Object? raw,
  PropField? field, {
  required String path,
  required int specVersion,
  required BindingContext context,
}) {
  if (specVersion < kTypedPropValuesSpecVersion) {
    return Left(
      SpecValidationError(
        '$path: $_typedForms exige specVersion '
        '$kTypedPropValuesSpecVersion ou maior (o spec é $specVersion)',
      ),
    );
  }

  return parsePropValue(raw, path: path).flatMap((value) {
    if (field != null && !field.isBindable) {
      return Left(
        SpecValidationError(
          '$path: a prop não aceita token do tema nem binding',
        ),
      );
    }
    if (value is! BoundPropValue) return const Right(unit);

    final sourcePath = '$path.${PropValue.bindKey}.source';
    final source = bindingSourceFor(value.source);
    if (source == null) {
      return Left(
        SpecValidationError(
          '$sourcePath: fonte "${value.source}" desconhecida',
        ),
      );
    }
    if (!source.isAvailableIn(context)) {
      return Left(
        SpecValidationError(
          '$sourcePath: fonte "${value.source}" não está disponível em '
          '${_contextLabel(context)}',
        ),
      );
    }

    if (field != null && field.isRequired && value.fallback == null) {
      return Left(
        SpecValidationError(
          '$path: binding em prop obrigatória exige fallback',
        ),
      );
    }
    return const Right(unit);
  });
}

String _contextLabel(BindingContext context) => switch (context) {
  BindingContext.page => 'página',
  BindingContext.component => 'componente',
  BindingContext.action => 'ação',
};
