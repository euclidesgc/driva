import 'package:sdui_core/sdui_core.dart';

/// Campos presentes em todos os [nodes] com o mesmo tipo de campo, na ordem do
/// primeiro nó. Tipos sem descritor não têm campo, logo zeram a interseção.
List<PropField> commonFields(List<SduiNode> nodes) {
  if (nodes.isEmpty) return const [];
  final descriptors = [for (final n in nodes) descriptorFor(n.type)];
  if (descriptors.any((d) => d == null)) return const [];
  return [
    for (final field in descriptors.first!.fields)
      if (descriptors.skip(1).every((d) {
        final other = d!.fieldOf(field.key);
        return other != null && other.kind == field.kind;
      }))
        field,
  ];
}

/// `true` quando os nós não têm o mesmo valor para [key] (ausente conta como
/// o valor padrão do campo, quando ele existe).
bool mixedValue(List<SduiNode> nodes, String key) {
  if (nodes.length < 2) return false;
  Object? valueOf(SduiNode n) {
    final value = n.properties[key];
    return value ?? descriptorFor(n.type)?.defaultValueOf(key);
  }

  final first = valueOf(nodes.first);
  return nodes.skip(1).any((n) => valueOf(n) != first);
}
