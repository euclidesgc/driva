import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateProjectUseCase {
  const CreateProjectUseCase({required this.repository});
  final ProjectsRepository repository;

  Future<Either<Failure, Project>> call({
    required String title,
    String? description,
    ProjectImageInput? image,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('O título do projeto é obrigatório.')),
      );
    }
    if (trimmedTitle.length > 120) {
      return Future.value(
        const Left(
          ValidationFailure('O título do projeto deve ter até 120 caracteres.'),
        ),
      );
    }
    final trimmedDescription = description?.trim();
    if ((trimmedDescription?.length ?? 0) > 280) {
      return Future.value(
        const Left(
          ValidationFailure(
            'A descrição do projeto deve ter até 280 caracteres.',
          ),
        ),
      );
    }
    return repository.createProject(
      title: trimmedTitle,
      description: (trimmedDescription?.isEmpty ?? true)
          ? null
          : trimmedDescription,
      image: image,
    );
  }
}
