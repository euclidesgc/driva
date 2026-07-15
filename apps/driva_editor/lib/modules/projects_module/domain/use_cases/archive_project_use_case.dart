import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/entities.dart';
import '../repositories/projects_repository.dart';

class ArchiveProjectUseCase {
  final ProjectsRepository repository;
  const ArchiveProjectUseCase({required this.repository});

  Future<Either<Failure, Project>> call(String id) =>
      repository.archiveProject(id);
}
