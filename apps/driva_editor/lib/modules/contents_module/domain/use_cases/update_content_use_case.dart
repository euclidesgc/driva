import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/util/slug.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/contents_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateContentUseCase {
  const UpdateContentUseCase({required this.repository});
  final ContentsRepository repository;

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
