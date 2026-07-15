import 'package:equatable/equatable.dart';

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

  final String slug;
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
