import 'package:equatable/equatable.dart';

/// Uma categoria: nó de uma árvore por projeto (Projeto → Categorias →
/// Conteúdos). `parentId` nulo é raiz (ex.: a categoria seed "Geral").
///
/// A lista chega **flat** da API — montar a árvore a partir de `parentId` é
/// derivação (fica para um use case/helper ou para a presentation, decisão da
/// P2). Esta entidade só carrega o nó.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.projectId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
  });

  final String id;
  final String projectId;
  final String name;

  /// `null` quando o nó é raiz.
  final String? parentId;

  final DateTime createdAt;
  final DateTime updatedAt;

  Category copyWith({
    String? id,
    String? projectId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? Function()? parentId,
  }) {
    return Category(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId != null ? parentId() : this.parentId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    name,
    parentId,
    createdAt,
    updatedAt,
  ];
}
