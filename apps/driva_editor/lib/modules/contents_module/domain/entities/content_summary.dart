import 'package:equatable/equatable.dart';

/// Resumo de um conteúdo para a listagem (o spec completo só é carregado no
/// editor).
class ContentSummary extends Equatable {
  const ContentSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;

  /// Referência técnica do conteúdo no código do app cliente. Único por
  /// projeto.
  final String slug;

  /// Categoria à qual o conteúdo pertence — todo conteúdo tem uma (a "Geral"
  /// é o destino default quando a escrita omite `categoryId`).
  final String categoryId;

  final String? description;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    categoryId,
    description,
    updatedAt,
  ];
}
