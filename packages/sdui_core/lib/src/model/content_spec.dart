import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/model/sdui_node.dart';

class ContentSpec extends Equatable {
  const ContentSpec({
    required this.specVersion,
    required this.id,
    required this.name,
    required this.slug,
    this.root,
    this.description,
    this.safeArea = const {},
  });

  final int specVersion;
  final String id;
  final String name;
  final String slug;
  final String? description;
  final SduiNode? root;

  /// Props da área segura que embrulha a página — mesmas chaves de
  /// `safeAreaDescriptor`. Vazio significa "tudo no padrão"; quem desenha
  /// resolve a ausência pelo descriptor, como faz com as props de um nó.
  final Map<String, dynamic> safeArea;

  /// [root] é função-getter porque `SduiNode?` não distinguiria "não passei"
  /// de "setar null".
  ContentSpec copyWith({
    int? specVersion,
    String? id,
    String? name,
    String? slug,
    String? description,
    SduiNode? Function()? root,
    Map<String, dynamic>? safeArea,
  }) {
    return ContentSpec(
      specVersion: specVersion ?? this.specVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      root: root != null ? root() : this.root,
      safeArea: safeArea ?? this.safeArea,
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
      if (safeArea.isNotEmpty) 'safeArea': safeArea,
      if (root != null) 'root': root!.toJson(),
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
    safeArea,
  ];
}
