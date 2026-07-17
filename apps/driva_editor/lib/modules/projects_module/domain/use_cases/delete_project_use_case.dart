import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteProjectUseCase {
  const DeleteProjectUseCase({required this.repository});
  final ProjectsRepository repository;

  Future<Either<Failure, Unit>> call(String id) => repository.deleteProject(id);
}
