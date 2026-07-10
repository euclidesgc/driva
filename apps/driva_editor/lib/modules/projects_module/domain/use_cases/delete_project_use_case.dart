import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/projects_repository.dart';

/// Passa-fica de propósito (Apêndice D do livro): a forma previsível vale o
/// boilerplate.
class DeleteProjectUseCase {
  final ProjectsRepository repository;
  const DeleteProjectUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) => repository.deleteProject(id);
}
