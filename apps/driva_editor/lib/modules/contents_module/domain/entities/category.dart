import 'package:equatable/equatable.dart';

/// Uma categoria: nó de uma árvore por projeto (Projeto → Categorias →
/// Conteúdos). `parentId` nulo é raiz (ex.: a categoria seed "Geral").
///
/// A lista chega **flat** da API — montar a árvore a partir de `parentId` é
/// derivação (fica para um use case/helper ou para a presentation, decisão da
/// P2). Esta entidade só carrega o nó.
///
/// Sem `createdAt`/`updatedAt`: o backend não os devolve para categoria (só
/// para conteúdo) — contrato confirmado por curl direto na API.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.projectId,
    required this.name,
    required this.contentCount,
    this.parentId,
  });

  final String id;
  final String projectId;
  final String name;

  /// `null` quando o nó é raiz.
  final String? parentId;

  /// Nº de conteúdos **diretos** desta categoria (não soma subcategorias) —
  /// adendo P3, `_count` do Prisma em `GET /v1/categories`. Sempre presente.
  final int contentCount;

  Category copyWith({
    String? id,
    String? projectId,
    String? name,
    int? contentCount,
    String? Function()? parentId,
  }) {
    return Category(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      contentCount: contentCount ?? this.contentCount,
      parentId: parentId != null ? parentId() : this.parentId,
    );
  }

  @override
  List<Object?> get props => [id, projectId, name, parentId, contentCount];
}
