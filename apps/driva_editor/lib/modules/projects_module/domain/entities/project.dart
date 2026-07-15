import 'package:equatable/equatable.dart';

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
    this.archivedAt,
  });

  final String id;
  final String title;

  final String? description;

  final String? imageUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  final int contentCount;
  final int categoryCount;

  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? contentCount,
    int? categoryCount,
    String? Function()? description,
    String? Function()? imageUrl,
    DateTime? Function()? archivedAt,
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
      archivedAt: archivedAt != null ? archivedAt() : this.archivedAt,
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
    archivedAt,
  ];
}
