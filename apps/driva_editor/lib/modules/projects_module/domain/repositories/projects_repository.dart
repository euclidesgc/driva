import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ProjectsRepository {
  Future<Either<Failure, List<Project>>> getProjects({bool archived = false});

  Future<Either<Failure, Project>> getProject(String id);

  Future<Either<Failure, Project>> createProject({
    required String title,
    String? description,
    ProjectImageInput? image,
  });

  Future<Either<Failure, Project>> updateProject(
    String id, {
    String? title,
    String? description,
    ProjectImageInput? image,
    bool removeImage = false,
  });

  Future<Either<Failure, Project>> archiveProject(String id);

  Future<Either<Failure, Project>> unarchiveProject(String id);

  Future<Either<Failure, Unit>> deleteProject(String id);
}
