/// Representação em árvore de um nó do spec, decodificado do JSON.
///
/// Espelho mínimo do `Node` do `@widgetmill/spec`. A garantia contra drift são
/// os testes golden que consomem `packages/spec/fixtures` (não codegen).
class SduiNode {
  const SduiNode({
    required this.type,
    this.props = const {},
    this.events = const {},
    this.child,
    this.children = const [],
  });

  /// Identificador do primitivo (`container`, `text`, ...).
  final String type;

  /// Props do primitivo (formato cru do JSON; cada builder interpreta o que usa).
  final Map<String, dynamic> props;

  /// Eventos → lista de ações (ex.: `onTap`).
  final Map<String, dynamic> events;

  /// Filho único (primitivos de 1 filho).
  final SduiNode? child;

  /// Filhos (primitivos de N filhos).
  final List<SduiNode> children;

  factory SduiNode.fromJson(Map<String, dynamic> json) {
    final childJson = json['child'];
    final childrenJson = json['children'];
    return SduiNode(
      type: json['type'] as String,
      props: _asMap(json['props']),
      events: _asMap(json['events']),
      child: childJson is Map
          ? SduiNode.fromJson(childJson.cast<String, dynamic>())
          : null,
      children: childrenJson is List
          ? childrenJson
              .map((e) => SduiNode.fromJson((e as Map).cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
    );
  }

  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const {};
}
