import 'package:equatable/equatable.dart';

class PublishedSummary extends Equatable {
  const PublishedSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, slug, updatedAt];
}
