import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetProjectsUseCase {
  const GetProjectsUseCase({required this.repository});
  final ProjectsRepository repository;

  Future<Either<Failure, List<Project>>> call({bool archived = false}) async {
    final result = await repository.getProjects(archived: archived);
    return result.map(
      (projects) =>
          projects.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }
}
