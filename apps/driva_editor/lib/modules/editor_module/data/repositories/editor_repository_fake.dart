import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/dev/fake_contents_store.dart';
import '../../../../core/error/error.dart';
import '../../domain/repositories/editor_repository.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Compartilha o
/// [FakeContentsStore] com o contents_module: criar na lista → abrir no editor.
class EditorRepositoryFake implements EditorRepository {
  final FakeContentsStore store;
  EditorRepositoryFake(this.store);

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, ContentSpec>> loadContent(String id) async {
    await Future<void>.delayed(_latency);
    final content = store.find(id);
    if (content == null) return const Left(NotFoundFailure());
    return Right(content);
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(ContentSpec content) async {
    await Future<void>.delayed(_latency);
    if (store.find(content.id) == null) return const Left(NotFoundFailure());
    store.save(content);
    return const Right(unit);
  }
}
