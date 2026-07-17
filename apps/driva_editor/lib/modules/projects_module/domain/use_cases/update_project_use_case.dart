import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateProjectUseCase {
  const UpdateProjectUseCase({required this.repository});
  final ProjectsRepository repository;

  Future<Either<Failure, Project>> call(
    String id, {
    String? title,
    String? description,
    ProjectImageInput? image,
    bool removeImage = false,
  }) {
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null) {
      if (trimmedTitle.isEmpty) {
        return Future.value(
          const Left(ValidationFailure('O título do projeto é obrigatório.')),
        );
      }
      if (trimmedTitle.length > 120) {
        return Future.value(
          const Left(
            ValidationFailure(
              'O título do projeto deve ter até 120 caracteres.',
            ),
          ),
        );
      }
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
    if (image != null && removeImage) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Não é possível enviar uma imagem nova e remover a imagem ao '
            'mesmo tempo.',
          ),
        ),
      );
    }
    return repository.updateProject(
      id,
      title: trimmedTitle,
      description: trimmedDescription,
      image: image,
      removeImage: removeImage,
    );
  }
}
