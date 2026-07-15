import 'package:equatable/equatable.dart';

/// Sem `createdAt`/`updatedAt`: o backend não os devolve para categoria.
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

  final String? parentId;
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
