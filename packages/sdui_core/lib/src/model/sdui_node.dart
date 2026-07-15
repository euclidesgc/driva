import 'package:equatable/equatable.dart';

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

  final Map<String, dynamic> events;

  final SduiNode? child;
  final List<SduiNode> children;

  /// [child] é função-getter porque `SduiNode?` não distinguiria "não passei"
  /// de "setar null".
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
