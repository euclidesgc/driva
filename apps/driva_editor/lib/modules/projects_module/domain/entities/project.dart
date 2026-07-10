import 'package:equatable/equatable.dart';

/// Um projeto: o novo topo da hierarquia (Projeto → Categorias → Conteúdos).
///
/// Cobre tanto o card da listagem quanto o detalhe — o payload de lista já
/// traz tudo que o card precisa (title/description/imageUrl/updatedAt) e o
/// detalhe só acrescenta `createdAt`; não há spec pesado como em conteúdo
/// que justifique um split summary/detail aqui. **Sem `slug`** (decisão
/// travada no PRD): o `id` basta como referência.
class Project extends Equatable {
  const Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.contentCount,
    required this.categoryCount,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String title;

  final String? description;

  /// URL servível da imagem do projeto; `null` quando o projeto não tem
  /// imagem (a UI mostra um placeholder). A chave interna de storage
  /// (`imageKey`) é um detalhe do backend e não vaza para o domain.
  final String? imageUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nº de conteúdos do projeto (`_count` do Prisma) — adendo P3 ao
  /// contrato de `GET /v1/projects` da feature 09. Sempre presente.
  final int contentCount;

  /// Nº de categorias do projeto (`_count` do Prisma) — mesmo adendo P3.
  final int categoryCount;

  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? contentCount,
    int? categoryCount,
    String? Function()? description,
    String? Function()? imageUrl,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentCount: contentCount ?? this.contentCount,
      categoryCount: categoryCount ?? this.categoryCount,
      description: description != null ? description() : this.description,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    createdAt,
    updatedAt,
    contentCount,
    categoryCount,
  ];
}
