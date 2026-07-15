import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.contentCount,
    required super.categoryCount,
    super.description,
    super.imageUrl,
    super.archivedAt,
  });

  // O backend serve `imageUrl`, nunca `imageKey` (chave interna de storage).
  static final _schema = z.map({
    'id': z.string().min(1),
    'title': z.string().min(1),
    'description': z.string().optional(),
    'imageUrl': z.string().nullable().optional(),
    'createdAt': z.date(),
    'updatedAt': z.date(),
    'contentCount': z.int(),
    'categoryCount': z.int(),
    'archivedAt': z.date().nullable().optional(),
  });

  static Either<Failure, ProjectModel> tryParse(Map<String, dynamic> map) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      ProjectModel(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String?,
        imageUrl: data['imageUrl'] as String?,
        createdAt: data['createdAt'] as DateTime,
        updatedAt: data['updatedAt'] as DateTime,
        contentCount: data['contentCount'] as int,
        categoryCount: data['categoryCount'] as int,
        archivedAt: data['archivedAt'] as DateTime?,
      ),
    );
  }
}
