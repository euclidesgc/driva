import 'package:equatable/equatable.dart';

import 'sdui_node.dart';

/// O spec de um conteúdo SDUI (specVersion 1).
///
/// O [root] é sempre um nó `column`: os blocos de topo do conteúdo são
/// `root.children`. O [slug] identifica o conteúdo dentro do projeto.
class ContentSpec extends Equatable {
  const ContentSpec({
    required this.specVersion,
    required this.id,
    required this.name,
    required this.slug,
    required this.root,
    this.description,
  });

  final int specVersion;
  final String id;
  final String name;
  final String slug;
  final String? description;
  final SduiNode root;

  ContentSpec copyWith({
    int? specVersion,
    String? id,
    String? name,
    String? slug,
    String? description,
    SduiNode? root,
  }) {
    return ContentSpec(
      specVersion: specVersion ?? this.specVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      root: root ?? this.root,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specVersion': specVersion,
      'kind': 'content',
      'id': id,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      'root': root.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    specVersion,
    id,
    name,
    slug,
    description,
    root,
  ];
}
