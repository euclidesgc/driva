import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/field_kind.dart';
import 'package:sdui_core/src/catalog/widget_catalog.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/schema/prop_value_schema.dart';

enum BoundValueDisplay { fallback, preview }

/// Só as props do próprio nó: os filhos passam por aqui quando o renderer
/// desenha cada um. Prop removida deixa o builder usar o próprio default.
SduiNode resolveBoundProps(
  SduiNode node, {
  BoundValueDisplay display = BoundValueDisplay.fallback,
}) {
  final resolved = <String, dynamic>{};
  var changed = false;
  for (final entry in node.properties.entries) {
    final outcome = _resolve(node.type, entry.key, entry.value, display);
    if (identical(outcome, _keep)) {
      resolved[entry.key] = entry.value;
      continue;
    }
    changed = true;
    if (outcome != null) resolved[entry.key] = outcome;
  }
  return changed ? node.copyWith(properties: resolved) : node;
}

const Object _keep = Object();

Object? _resolve(
  String type,
  String key,
  Object? raw,
  BoundValueDisplay display,
) {
  final parsed = parsePropValue(raw);
  return switch (parsed) {
    Left() when _isBindForm(raw) => null,
    Left() => _keep,
    Right(value: final BoundPropValue bound) when bound.isLegacy =>
      _isTextField(type, key) ? _keep : null,
    Right(value: final BoundPropValue bound) => switch (display) {
      BoundValueDisplay.preview => bound.preview ?? bound.fallback,
      BoundValueDisplay.fallback => bound.fallback,
    },
    Right() => _keep,
  };
}

bool _isBindForm(Object? raw) =>
    raw is Map && raw.containsKey(PropValue.bindKey);

bool _isTextField(String type, String key) {
  final fields = descriptorFor(type)?.fields ?? const [];
  for (final field in fields) {
    if (field.key == key) return field.kind == FieldKind.string;
  }
  return true;
}
