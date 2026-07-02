import 'package:equatable/equatable.dart';

import 'sdui_node.dart';

/// O spec de uma página SDUI (specVersion 1).
///
/// A página é um **fragmento** anexado a uma tela já existente do app
/// ([screenTarget]), não uma rota de tela inteira. O [root] é sempre um nó
/// `column`: os blocos de topo da página são `root.children`.
class PageSpec extends Equatable {
  const PageSpec({
    required this.specVersion,
    required this.id,
    required this.name,
    required this.screenTarget,
    required this.root,
  });

  final int specVersion;
  final String id;
  final String name;
  final String screenTarget;
  final SduiNode root;

  PageSpec copyWith({
    int? specVersion,
    String? id,
    String? name,
    String? screenTarget,
    SduiNode? root,
  }) {
    return PageSpec(
      specVersion: specVersion ?? this.specVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      screenTarget: screenTarget ?? this.screenTarget,
      root: root ?? this.root,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specVersion': specVersion,
      'kind': 'page',
      'id': id,
      'name': name,
      'screenTarget': screenTarget,
      'root': root.toJson(),
    };
  }

  @override
  List<Object?> get props => [specVersion, id, name, screenTarget, root];
}
