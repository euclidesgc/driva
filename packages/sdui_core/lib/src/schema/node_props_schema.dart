import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/binding_source_catalog.dart';
import 'package:sdui_core/src/catalog/field_kind.dart';
import 'package:sdui_core/src/catalog/prop_field.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/theme_color_role.dart';
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
  bool tolerant = false,
}) {
  for (final MapEntry(:key, :value) in props.entries) {
    if (!PropValue.isTypedForm(value)) continue;
    final result = _validateTypedProp(
      value,
      descriptor.fieldOf(key),
      path: '$path.$key',
      specVersion: specVersion,
      context: context,
      tolerant: tolerant,
    );
    if (result.isLeft()) return result;
  }
  return const Right(unit);
}

Either<SpecValidationError, Unit> _validateTypedProp(
  Object? raw,
  PropField? field, {
  required String path,
  required int specVersion,
  required BindingContext context,
  required bool tolerant,
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
    if (value is ThemeRefPropValue) {
      return tolerant
          ? const Right(unit)
          : _validateThemeRef(value, field, path: path);
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

/// O modo tolerante (o do app cliente) deixa passar o papel criado depois e a
/// prop que ele ainda não conhece: o renderer os desenha como prop ausente em
/// vez de recusar a página inteira.
Either<SpecValidationError, Unit> _validateThemeRef(
  ThemeRefPropValue value,
  PropField? field, {
  required String path,
}) {
  if (field?.kind != FieldKind.color) {
    return Left(
      SpecValidationError(
        '$path: ${PropValue.themeKey} só vale em prop de cor',
      ),
    );
  }
  if (ThemeColorRole.fromName(value.token) == null) {
    return Left(
      SpecValidationError(
        '$path.${PropValue.themeKey}: papel de cor "${value.token}" '
        'desconhecido',
      ),
    );
  }
  return const Right(unit);
}

String _contextLabel(BindingContext context) => switch (context) {
  BindingContext.page => 'página',
  BindingContext.component => 'componente',
  BindingContext.action => 'ação',
};
