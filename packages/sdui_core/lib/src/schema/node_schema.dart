import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/widget_catalog.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/dimension_value.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/schema/node_props_schema.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:sdui_core/src/schema/spec_version.dart';
import 'package:zard/zard.dart';

// O z.map do zard só devolve as chaves declaradas: `props`/`events` ficam de
// fora daqui de propósito, senão seriam descartados.
final ZMap _nodeScalars = z.map({
  'id': z.string().min(1),
  'type': z.string().min(1),
});

Either<SpecValidationError, SduiNode> parseNode(
  Map<String, dynamic> json, {
  String path = 'root',
  int specVersion = kOldestSpecVersion,
}) {
  final result = _nodeScalars.safeParse(json);
  if (!result.success) {
    return Left(
      SpecValidationError('$path: ${z.prettifyError(result.error!)}'),
    );
  }
  final id = result.data!['id'] as String;
  final type = result.data!['type'] as String;

  final descriptor = descriptorFor(type);
  if (descriptor == null) {
    return Left(SpecValidationError('$path: tipo "$type" fora do catálogo'));
  }

  final rawProps = json['props'];
  if (rawProps != null && rawProps is! Map) {
    return Left(SpecValidationError('$path.props: esperado um objeto'));
  }
  if (rawProps is Map) {
    final validated = validateNodeProps(
      rawProps.cast<String, dynamic>(),
      descriptor,
      path: '$path.props',
      specVersion: specVersion,
      context: BindingContext.page,
    );
    if (validated case Left(:final value)) return Left(value);
  }
  final rawEvents = json['events'];
  if (rawEvents != null && rawEvents is! Map) {
    return Left(SpecValidationError('$path.events: esperado um objeto'));
  }

  final rawChild = json['child'];
  final rawChildren = json['children'];

  switch (descriptor.slot) {
    case SlotKind.none:
      if (rawChild != null || rawChildren != null) {
        return Left(
          SpecValidationError('$path: "$type" é folha e não aceita filhos'),
        );
      }
    case SlotKind.single:
      if (rawChildren != null) {
        return Left(
          SpecValidationError(
            '$path: "$type" aceita um único filho (use "child")',
          ),
        );
      }
    case SlotKind.multi:
      if (rawChild != null) {
        return Left(
          SpecValidationError(
            '$path: "$type" aceita vários filhos (use "children")',
          ),
        );
      }
  }

  final limitError = _validateLimits(path, rawProps);
  if (limitError != null) return Left(limitError);

  SduiNode? child;
  if (rawChild != null) {
    if (rawChild is! Map) {
      return Left(SpecValidationError('$path.child: esperado um objeto'));
    }
    final parsed = parseNode(
      rawChild.cast<String, dynamic>(),
      path: '$path.child',
      specVersion: specVersion,
    );
    if (parsed.isLeft()) return parsed;
    child = parsed.toNullable();
  }

  final children = <SduiNode>[];
  if (rawChildren != null) {
    if (rawChildren is! List) {
      return Left(SpecValidationError('$path.children: esperada uma lista'));
    }
    for (var i = 0; i < rawChildren.length; i++) {
      final item = rawChildren[i];
      if (item is! Map) {
        return Left(
          SpecValidationError('$path.children[$i]: esperado um objeto'),
        );
      }
      final parsed = parseNode(
        item.cast<String, dynamic>(),
        path: '$path.children[$i]',
        specVersion: specVersion,
      );
      if (parsed.isLeft()) return parsed;
      children.add(parsed.toNullable()!);
    }
  }

  return Right(
    SduiNode(
      id: id,
      type: type,
      properties: (rawProps as Map?)?.cast<String, dynamic>() ?? const {},
      events: (rawEvents as Map?)?.cast<String, dynamic>() ?? const {},
      child: child,
      children: children,
    ),
  );
}

/// min > max só é comparável quando os dois lados são pixels: percentual e
/// `inf` dependem do espaço do pai, que o kernel não conhece.
SpecValidationError? _validateLimits(String path, Object? rawProps) {
  if (rawProps is! Map) return null;
  const pairs = [('minWidth', 'maxWidth'), ('minHeight', 'maxHeight')];
  for (final (minKey, maxKey) in pairs) {
    final min = DimensionValue.parse(rawProps[minKey]);
    final max = DimensionValue.parse(rawProps[maxKey]);
    if (min is PixelDimension &&
        max is PixelDimension &&
        min.pixels > max.pixels) {
      return SpecValidationError(
        '$path.props: $minKey (${min.pixels}) maior que $maxKey '
        '(${max.pixels})',
      );
    }
  }
  return null;
}
