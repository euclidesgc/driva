import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/dev/fake_pages_store.dart';
import '../../../../core/error/error.dart';
import '../../domain/repositories/editor_repository.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Compartilha o
/// [FakePagesStore] com o pages_module: criar na lista → abrir no editor.
class EditorRepositoryFake implements EditorRepository {
  final FakePagesStore store;
  EditorRepositoryFake(this.store);

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, PageSpec>> loadPage(String id) async {
    await Future<void>.delayed(_latency);
    final page = store.find(id);
    if (page == null) return const Left(NotFoundFailure());
    return Right(page);
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(PageSpec page) async {
    await Future<void>.delayed(_latency);
    if (store.find(page.id) == null) return const Left(NotFoundFailure());
    store.save(page);
    return const Right(unit);
  }
}
