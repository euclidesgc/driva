import 'package:equatable/equatable.dart';

/// Resumo de um conteúdo para a listagem (o spec completo só é carregado no
/// editor).
class ContentSummary extends Equatable {
  const ContentSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;

  /// Referência técnica do conteúdo no código do app cliente. Único por
  /// projeto.
  final String slug;

  final String? description;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, slug, description, updatedAt];
}
