import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../../../core/util/slug.dart';
import '../entities/content_summary.dart';
import '../repositories/contents_repository.dart';

class CreateContentUseCase {
  final ContentsRepository repository;
  const CreateContentUseCase({required this.repository});

  Future<Either<Failure, ContentSummary>> call({
    required String name,
    required String slug,
    String? description,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('O nome do conteúdo é obrigatório.')),
      );
    }
    final trimmedSlug = slug.trim();
    if (!SlugUtil.isValid(trimmedSlug)) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Slug inválido. Use letras minúsculas, números e hifens, '
            'começando por uma letra.',
          ),
        ),
      );
    }
    final trimmedDescription = description?.trim();
    return repository.createContent(
      name: trimmedName,
      slug: trimmedSlug,
      description: (trimmedDescription?.isEmpty ?? true)
          ? null
          : trimmedDescription,
    );
  }
}
