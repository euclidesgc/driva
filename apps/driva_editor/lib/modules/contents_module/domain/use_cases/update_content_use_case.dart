import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../../../core/util/slug.dart';
import '../entities/content_summary.dart';
import '../repositories/contents_repository.dart';

class UpdateContentUseCase {
  final ContentsRepository repository;
  const UpdateContentUseCase({required this.repository});

  Future<Either<Failure, ContentSummary>> call(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? categoryId,
  }) {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('O nome do conteúdo é obrigatório.')),
      );
    }
    final trimmedSlug = slug?.trim();
    if (trimmedSlug != null && !SlugUtil.isValid(trimmedSlug)) {
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
    return repository.updateContent(
      id,
      name: trimmedName,
      slug: trimmedSlug,
      description: trimmedDescription,
      categoryId: categoryId,
    );
  }
}
