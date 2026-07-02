import 'package:equatable/equatable.dart';

/// Um nó da árvore do spec SDUI.
///
/// Todo nó tem [id] (seleção/reordenação no editor), [type] (primitivo do
/// catálogo) e [properties] no formato cru do JSON (chave `props` no spec) —
/// cada builder do renderer interpreta o que usa. Slots: [child] para
/// primitivos de 1 filho, [children] para primitivos de N filhos.
///
/// O campo chama-se `properties` (e não `props`) porque `props` é o getter de
/// igualdade do Equatable.
class SduiNode extends Equatable {
  const SduiNode({
    required this.id,
    required this.type,
    this.properties = const {},
    this.events = const {},
    this.child,
    this.children = const [],
  });

  final String id;
  final String type;
  final Map<String, dynamic> properties;

  /// Eventos → lista de ações (ex.: `onPressed`). Ação é dado: o editor não
  /// executa, só o app cliente.
  final Map<String, dynamic> events;

  final SduiNode? child;
  final List<SduiNode> children;

  /// Cópia imutável. [child] usa função-getter para permitir "setar null"
  /// (a armadilha do copyWith com campo nullable, capítulo 12 do livro).
  SduiNode copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? events,
    SduiNode? Function()? child,
    List<SduiNode>? children,
  }) {
    return SduiNode(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      events: events ?? this.events,
      child: child != null ? child() : this.child,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (properties.isNotEmpty) 'props': properties,
      if (events.isNotEmpty) 'events': events,
      if (child != null) 'child': child!.toJson(),
      if (children.isNotEmpty)
        'children': [for (final c in children) c.toJson()],
    };
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    type,
    properties,
    events,
    child,
    children,
  ];
}
