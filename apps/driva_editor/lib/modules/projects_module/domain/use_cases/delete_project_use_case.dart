import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/projects_repository.dart';

class DeleteProjectUseCase {
  final ProjectsRepository repository;
  const DeleteProjectUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) => repository.deleteProject(id);
}
