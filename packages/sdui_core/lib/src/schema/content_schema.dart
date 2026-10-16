import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/binding_source_ids.dart';
import 'package:sdui_core/src/catalog/safe_area_descriptor.dart';
import 'package:sdui_core/src/model/component_instance.dart';
import 'package:sdui_core/src/model/component_param.dart';
import 'package:sdui_core/src/model/content_kind.dart';
import 'package:sdui_core/src/model/content_spec.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/schema/component_declarations_schema.dart';
import 'package:sdui_core/src/schema/node_props_schema.dart';
import 'package:sdui_core/src/schema/node_schema.dart';
import 'package:sdui_core/src/schema/prop_value_schema.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:sdui_core/src/schema/spec_version.dart';
import 'package:zard/zard.dart';

final ZMap _contentEnvelope = z.map({
  'specVersion': z.int(),
  'kind': z.$enum([for (final kind in ContentKind.values) kind.name]),
  'id': z.string().min(1),
  'name': z.string().min(1),
  'slug': z.string().regex(RegExp(r'^[a-z][a-z0-9-]*$')),
  'description': z.string().optional(),
});

Either<SpecValidationError, ContentSpec> parseContentSpec(
  Map<String, dynamic> json, {
  bool tolerant = false,
}) {
  final result = _contentEnvelope.safeParse(json);
  if (!result.success) {
    return Left(SpecValidationError(z.prettifyError(result.error!)));
  }
  final data = result.data!;

  final specVersion = data['specVersion'] as int;
  if (specVersion < kOldestSpecVersion || specVersion > kLatestSpecVersion) {
    return Left(
      SpecValidationError(
        'specVersion $specVersion não suportada '
        '(suportadas: $kOldestSpecVersion a $kLatestSpecVersion)',
      ),
    );
  }

  final kind = ContentKind.values.byName(data['kind'] as String);
  final isComponent = kind == ContentKind.component;
  final rawSafeArea = json['safeArea'];

  if (isComponent) {
    if (rawSafeArea != null) {
      return const Left(
        SpecValidationError('safeArea: componente não tem área segura'),
      );
    }
  } else {
    if (json['params'] != null) {
      return const Left(
        SpecValidationError('params: só um componente declara parâmetros'),
      );
    }
    if (json['state'] != null) {
      return const Left(
        SpecValidationError('state: só um componente declara estado'),
      );
    }
    final safeAreaError = _validateSafeArea(
      rawSafeArea,
      specVersion: specVersion,
      tolerant: tolerant,
    );
    if (safeAreaError != null) return Left(safeAreaError);
  }

  final params = parseComponentParams(json['params']);
  if (params case Left(:final value)) return Left(value);
  final state = parseComponentState(json['state']);
  if (state case Left(:final value)) return Left(value);
  final declaredParams = params.getOrElse((_) => const []);
  final declaredState = state.getOrElse((_) => const []);

  ContentSpec build(SduiNode? root) => ContentSpec(
    specVersion: specVersion,
    id: data['id'] as String,
    name: data['name'] as String,
    slug: data['slug'] as String,
    description: data['description'] as String?,
    root: root,
    safeArea: (rawSafeArea as Map?)?.cast<String, dynamic>() ?? const {},
    kind: kind,
    params: declaredParams,
    state: declaredState,
  );

  final rawRoot = json['root'];
  if (rawRoot == null) {
    return Right(build(null));
  }
  if (rawRoot is! Map) {
    return const Left(SpecValidationError('root: esperado um objeto'));
  }

  return parseNode(
    rawRoot.cast<String, dynamic>(),
    specVersion: specVersion,
    tolerant: tolerant,
    context: isComponent ? BindingContext.component : BindingContext.page,
  ).flatMap((root) {
    if (!isComponent) return Right(build(root));
    final refError = _checkComponentParamRefs(
      root,
      _byName(declaredParams),
      path: 'root',
    );
    return refError == null ? Right(build(root)) : Left(refError);
  });
}

SpecValidationError? _validateSafeArea(
  Object? rawSafeArea, {
  required int specVersion,
  required bool tolerant,
}) {
  if (rawSafeArea == null) return null;
  if (rawSafeArea is! Map) {
    return const SpecValidationError('safeArea: esperado um objeto');
  }
  return validateNodeProps(
    rawSafeArea.cast<String, dynamic>(),
    safeAreaDescriptor,
    path: 'safeArea',
    specVersion: specVersion,
    context: BindingContext.page,
    tolerant: tolerant,
  ).fold((error) => error, (_) => null);
}

Map<String, ComponentParam> _byName(List<ComponentParam> params) => {
  for (final param in params) param.name: param,
};

/// Roda depois do `parseNode` para não levar a lista de parâmetros por toda a
/// recursão e por `validateNodeProps`, que servem a qualquer nó. Nos `args` de
/// uma instância aninhada vale qualquer parâmetro declarado, inclusive ação e
/// slot, porque é assim que o componente de fora os repassa.
SpecValidationError? _checkComponentParamRefs(
  SduiNode node,
  Map<String, ComponentParam> params, {
  required String path,
}) {
  final isInstance = ComponentInstance.isInstance(node);
  final valuesPath = isInstance
      ? '$path.props.${ComponentInstance.argsKey}'
      : '$path.props';
  final values = isInstance ? ComponentInstance.argsOf(node) : node.properties;

  for (final MapEntry(:key, :value) in values.entries) {
    final error = _checkParamRef(
      value,
      params,
      path: '$valuesPath.$key',
      acceptsSpecial: isInstance,
    );
    if (error != null) return error;
  }

  final child = node.child;
  if (child != null) {
    final error = _checkComponentParamRefs(
      child,
      params,
      path: '$path.child',
    );
    if (error != null) return error;
  }
  for (var i = 0; i < node.children.length; i++) {
    final error = _checkComponentParamRefs(
      node.children[i],
      params,
      path: '$path.children[$i]',
    );
    if (error != null) return error;
  }
  return null;
}

SpecValidationError? _checkParamRef(
  Object? raw,
  Map<String, ComponentParam> params, {
  required String path,
  required bool acceptsSpecial,
}) {
  final value = parsePropValue(raw, path: path).toNullable();
  if (value is! BoundPropValue ||
      value.source != BindingSourceIds.componentParam) {
    return null;
  }

  final pathOfBind = '$path.${PropValue.bindKey}.path';
  final param = params[value.path];
  if (param == null) {
    return SpecValidationError(
      '$pathOfBind: parâmetro "${value.path}" não declarado no componente',
    );
  }
  if (!acceptsSpecial && !param.type.isData) {
    return SpecValidationError(
      '$pathOfBind: a prop não aceita parâmetro do tipo ${param.type.label} '
      '("${value.path}")',
    );
  }
  return null;
}
