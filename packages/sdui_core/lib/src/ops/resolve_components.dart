import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_source_ids.dart';
import 'package:sdui_core/src/model/component_instance.dart';
import 'package:sdui_core/src/model/content_kind.dart';
import 'package:sdui_core/src/model/content_spec.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/ops/component_resolution_error.dart';
import 'package:sdui_core/src/schema/prop_value_schema.dart';

typedef ComponentLookup = ContentSpec? Function(String componentId);

const int kMaxComponentDepth = 5;

typedef _Expansion = ({String id, String name});

typedef _Scope = ({
  String? idPrefix,
  ContentSpec? component,
  Map<String, dynamic> args,
  List<_Expansion> stack,
});

const _Scope _pageScope = (
  idPrefix: null,
  component: null,
  args: <String, dynamic>{},
  stack: <_Expansion>[],
);

/// Troca cada instância `type: "component"` pela cópia da `root` do
/// componente. Cada nó copiado recebe o id `'<id da instância>/<id original>'`,
/// e a instância aninhada já tem o id prefixado (`inst1/selo/texto`), então a
/// mesma entrada dá sempre os mesmos ids.
///
/// Um `$bind` `componentParam` vale o arg da instância; sem ele, o `default`
/// do parâmetro; sem ele, o `fallback` do binding; sem nenhum dos três, a
/// chave sai e o widget usa o próprio padrão.
///
/// `Right(null)` quando a raiz é uma instância de um componente sem `root`.
Either<ComponentResolutionError, SduiNode?> resolveComponents(
  SduiNode root,
  ComponentLookup lookup,
) => _resolveNode(root, _pageScope, lookup);

/// A mesma resolução para uma instância só, que o renderer desenha no lugar
/// dela: `Right(null)` quando o componente não tem `root`.
Either<ComponentResolutionError, SduiNode?> resolveComponentInstance(
  SduiNode instance,
  ComponentLookup lookup,
) => _resolveNode(instance, _pageScope, lookup);

Either<ComponentResolutionError, SduiNode?> _resolveNode(
  SduiNode node,
  _Scope scope,
  ComponentLookup lookup,
) {
  final id = scope.idPrefix == null ? node.id : '${scope.idPrefix}/${node.id}';
  if (ComponentInstance.isInstance(node)) {
    return _expandInstance(
      instanceId: id,
      componentId: ComponentInstance.componentIdOf(node) ?? '',
      args: _applyComponentParams(ComponentInstance.argsOf(node), scope),
      stack: scope.stack,
      lookup: lookup,
    );
  }

  SduiNode? child;
  if (node.child case final original?) {
    switch (_resolveNode(original, scope, lookup)) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        child = value;
    }
  }

  final children = <SduiNode>[];
  for (final original in node.children) {
    switch (_resolveNode(original, scope, lookup)) {
      case Left(:final value):
        return Left(value);
      case Right(:final value?):
        children.add(value);
      case Right():
        break;
    }
  }

  return Right(
    node.copyWith(
      id: id,
      properties: _applyComponentParams(node.properties, scope),
      child: () => child,
      children: children,
    ),
  );
}

Either<ComponentResolutionError, SduiNode?> _expandInstance({
  required String instanceId,
  required String componentId,
  required Map<String, dynamic> args,
  required List<_Expansion> stack,
  required ComponentLookup lookup,
}) {
  final component = lookup(componentId);
  if (component == null || component.kind != ContentKind.component) {
    return Left(
      ComponentNotFound(instanceId: instanceId, componentId: componentId),
    );
  }

  final chain = [for (final expansion in stack) expansion.name, component.name];
  if (stack.any((expansion) => expansion.id == componentId)) {
    return Left(ComponentCycle(instanceId: instanceId, chain: chain));
  }
  if (chain.length > kMaxComponentDepth) {
    return Left(
      ComponentDepthExceeded(
        instanceId: instanceId,
        limit: kMaxComponentDepth,
        chain: chain,
      ),
    );
  }

  final argError = _checkArgs(instanceId, component, args);
  if (argError != null) return Left(argError);

  final root = component.root;
  if (root == null) return const Right(null);
  return _resolveNode(root, (
    idPrefix: instanceId,
    component: component,
    args: args,
    stack: [...stack, (id: componentId, name: component.name)],
  ), lookup);
}

ComponentResolutionError? _checkArgs(
  String instanceId,
  ContentSpec component,
  Map<String, dynamic> args,
) {
  for (final param in component.params) {
    final arg = args[param.name];
    if (arg == null) {
      if (param.isRequired && param.defaultValue == null) {
        return MissingRequiredArg(
          instanceId: instanceId,
          componentName: component.name,
          paramName: param.name,
        );
      }
      continue;
    }
    if (_isLiteral(arg) &&
        !param.type.accepts(
          arg,
          isList: param.isList,
          options: param.options,
        )) {
      return ArgTypeMismatch(
        instanceId: instanceId,
        componentName: component.name,
        paramName: param.name,
        expected: param.type,
        expectedList: param.isList,
      );
    }
  }
  return null;
}

bool _isLiteral(Object? raw) =>
    parsePropValue(raw).toNullable() is LiteralPropValue;

Map<String, dynamic> _applyComponentParams(
  Map<String, dynamic> values,
  _Scope scope,
) {
  final component = scope.component;
  if (component == null) return values;

  final applied = <String, dynamic>{};
  var changed = false;
  for (final MapEntry(:key, :value) in values.entries) {
    final binding = _componentParamBinding(value);
    if (binding == null) {
      applied[key] = value;
      continue;
    }
    changed = true;
    final replacement =
        scope.args[binding.path] ??
        component.paramNamed(binding.path)?.defaultValue ??
        binding.fallback;
    if (replacement != null) applied[key] = replacement;
  }
  return changed ? applied : values;
}

BoundPropValue? _componentParamBinding(Object? raw) =>
    switch (parsePropValue(raw)) {
      Right(value: final BoundPropValue bound)
          when bound.source == BindingSourceIds.componentParam =>
        bound,
      _ => null,
    };
