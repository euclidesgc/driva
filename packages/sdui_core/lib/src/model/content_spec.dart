import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/model/component_param.dart';
import 'package:sdui_core/src/model/component_state_variable.dart';
import 'package:sdui_core/src/model/content_kind.dart';
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
    this.kind = ContentKind.content,
    this.params = const [],
    this.state = const [],
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

  final ContentKind kind;
  final List<ComponentParam> params;
  final List<ComponentStateVariable> state;

  ComponentParam? paramNamed(String name) {
    for (final param in params) {
      if (param.name == name) return param;
    }
    return null;
  }

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
    ContentKind? kind,
    List<ComponentParam>? params,
    List<ComponentStateVariable>? state,
  }) {
    return ContentSpec(
      specVersion: specVersion ?? this.specVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      root: root != null ? root() : this.root,
      safeArea: safeArea ?? this.safeArea,
      kind: kind ?? this.kind,
      params: params ?? this.params,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specVersion': specVersion,
      'kind': kind.name,
      'id': id,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      if (safeArea.isNotEmpty) 'safeArea': safeArea,
      if (params.isNotEmpty)
        'params': [for (final param in params) param.toJson()],
      if (state.isNotEmpty)
        'state': [for (final variable in state) variable.toJson()],
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
    kind,
    params,
    state,
  ];
}
