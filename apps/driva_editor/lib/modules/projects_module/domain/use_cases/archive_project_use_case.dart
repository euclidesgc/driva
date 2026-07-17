import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:fpdart/fpdart.dart';

class ArchiveProjectUseCase {
  const ArchiveProjectUseCase({required this.repository});
  final ProjectsRepository repository;

  Future<Either<Failure, Project>> call(String id) =>
      repository.archiveProject(id);
}
