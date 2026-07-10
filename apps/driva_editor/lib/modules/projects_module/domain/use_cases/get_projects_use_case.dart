import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/entities.dart';
import '../repositories/projects_repository.dart';

class GetProjectsUseCase {
  final ProjectsRepository repository;
  const GetProjectsUseCase({required this.repository});

  Future<Either<Failure, List<Project>>> call({bool archived = false}) async {
    final result = await repository.getProjects(archived: archived);
    // Regra da listagem: mais recente primeiro. Roda só no caminho de sucesso.
    return result.map(
      (projects) =>
          projects.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }
}
