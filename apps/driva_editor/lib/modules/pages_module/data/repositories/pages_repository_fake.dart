import 'package:fpdart/fpdart.dart';

import '../../../../core/dev/fake_pages_store.dart';
import '../../../../core/error/error.dart';
import '../../domain/entities/page_summary.dart';
import '../../domain/repositories/pages_repository.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Um fake honra o
/// contrato de verdade: latência simulada e erros previstos.
class PagesRepositoryFake implements PagesRepository {
  final FakePagesStore store;
  PagesRepositoryFake(this.store);

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, List<PageSummary>>> getPages() async {
    await Future<void>.delayed(_latency);
    return Right([
      for (final page in store.pages)
        PageSummary(
          id: page.id,
          name: page.name,
          screenTarget: page.screenTarget,
          updatedAt: store.updatedAtOf(page.id),
        ),
    ]);
  }

  @override
  Future<Either<Failure, PageSummary>> createPage({
    required String name,
    required String screenTarget,
  }) async {
    await Future<void>.delayed(_latency);
    final page = store.create(name: name, screenTarget: screenTarget);
    return Right(
      PageSummary(
        id: page.id,
        name: page.name,
        screenTarget: page.screenTarget,
        updatedAt: store.updatedAtOf(page.id),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deletePage(String id) async {
    await Future<void>.delayed(_latency);
    if (!store.delete(id)) return const Left(NotFoundFailure());
    return const Right(unit);
  }
}
