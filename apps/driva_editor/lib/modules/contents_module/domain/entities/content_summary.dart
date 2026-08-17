import 'package:equatable/equatable.dart';

class ContentSummary extends Equatable {
  const ContentSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.updatedAt,
    required this.publishedAt,
    required this.hasUnpublishedChanges,
    this.description,
  });

  final String id;
  final String name;

  final String slug;
  final String categoryId;

  final String? description;
  final DateTime updatedAt;

  /// `null` = nunca publicado. Item 24 (publicação e versionamento).
  final DateTime? publishedAt;
  final bool hasUnpublishedChanges;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    categoryId,
    description,
    updatedAt,
    publishedAt,
    hasUnpublishedChanges,
  ];
}
