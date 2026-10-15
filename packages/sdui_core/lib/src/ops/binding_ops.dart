import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/ops/tree_ops.dart';
import 'package:sdui_core/src/schema/prop_value_schema.dart';

Object? literalUnder(Object? raw) {
  return switch (parsePropValue(raw)) {
    Right(value: LiteralPropValue(:final value)) => value,
    Right(value: final BoundPropValue bound) => bound.literal,
    _ => null,
  };
}

/// A fonte legada é gravada como `{{path}}`, que não tem onde guardar o
/// literal: remover depois apaga a chave.
SduiNode bindNodeProp(
  SduiNode root,
  String id,
  String key,
  BoundPropValue binding,
) {
  final node = findNode(root, id);
  if (node == null) return root;
  final stored = binding.isLegacy
      ? binding
      : BoundPropValue(
          source: binding.source,
          path: binding.path,
          transform: binding.transform,
          fallback: binding.fallback,
          preview: binding.preview,
          literal: literalUnder(node.properties[key]),
        );
  return updateNodeProps(root, id, {key: stored.toJson()});
}

SduiNode unbindNodeProp(SduiNode root, String id, String key) {
  final raw = findNode(root, id)?.properties[key];
  final isBound = switch (parsePropValue(raw)) {
    Right(value: BoundPropValue()) => true,
    _ => false,
  };
  if (!isBound) return root;
  return updateNodeProps(root, id, {key: literalUnder(raw)});
}
