import 'package:fpdart/fpdart.dart';

import '../../../../core/dev/fake_contents_store.dart';
import '../../../../core/error/error.dart';
import '../../../../core/util/slug.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/repositories/contents_repository.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Um fake honra o
/// contrato de verdade: latência simulada, colisão de slug traduzida em
/// `ConflictFailure` e erros previstos.
class ContentsRepositoryFake implements ContentsRepository {
  final FakeContentsStore store;
  ContentsRepositoryFake(this.store);

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, List<ContentSummary>>> getContents() async {
    await Future<void>.delayed(_latency);
    return Right([
      for (final content in store.contents)
        ContentSummary(
          id: content.id,
          name: content.name,
          slug: content.slug,
          description: content.description,
          updatedAt: store.updatedAtOf(content.id),
        ),
    ]);
  }

  @override
  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
  }) async {
    await Future<void>.delayed(_latency);
    if (store.slugExists(slug)) {
      return Left(
        ConflictFailure(suggestedSlug: SlugUtil.suggestFree(slug, store.slugs)),
      );
    }
    final content = store.create(
      name: name,
      slug: slug,
      description: description,
    );
    return Right(
      ContentSummary(
        id: content.id,
        name: content.name,
        slug: content.slug,
        description: content.description,
        updatedAt: store.updatedAtOf(content.id),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteContent(String id) async {
    await Future<void>.delayed(_latency);
    if (!store.delete(id)) return const Left(NotFoundFailure());
    return const Right(unit);
  }
}
