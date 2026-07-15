import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/entities.dart';
import '../repositories/projects_repository.dart';

class UnarchiveProjectUseCase {
  final ProjectsRepository repository;
  const UnarchiveProjectUseCase({required this.repository});

  Future<Either<Failure, Project>> call(String id) =>
      repository.unarchiveProject(id);
}
