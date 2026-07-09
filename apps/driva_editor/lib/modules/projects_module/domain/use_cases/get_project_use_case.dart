import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/entities.dart';
import '../repositories/projects_repository.dart';

/// Passa-fica de propósito (Apêndice D do livro): a forma previsível vale.
class GetProjectUseCase {
  final ProjectsRepository repository;
  const GetProjectUseCase({required this.repository});

  Future<Either<Failure, Project>> call(String id) => repository.getProject(id);
}
