import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Compartilha o
/// [FakeContentsStore] com o contents_module: criar na lista → abrir no editor.
class EditorRepositoryFake implements EditorRepository {
  EditorRepositoryFake(this.store);
  final FakeContentsStore store;

  static const _versionsPageLimit = 20;
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, LoadedContent>> loadContent(String id) async {
    await Future<void>.delayed(_latency);
    final content = store.find(id);
    if (content == null) return const Left(NotFoundFailure());
    return Right(
      LoadedContent(spec: content, publication: _publicationStateOf(id)),
    );
  }

  /// O fake guarda os pontos marcados em memória, na mesma sessão — sem
  /// isso, o histórico do modo de demonstração mostraria publicações e nunca
  /// um checkpoint, e a tela pareceria quebrada onde está correta.
  final _checkpoints = <String, List<LoadedContentCheckpoint>>{};

  @override
  Future<Either<Failure, ContentCheckpointsPage>> listCheckpoints(
    String id, {
    String? cursor,
  }) async {
    await Future<void>.delayed(_latency);
    if (store.find(id) == null) return const Left(NotFoundFailure());
    final rows = _checkpoints[id] ?? const <LoadedContentCheckpoint>[];
    return Right(
      ContentCheckpointsPage(
        items: [
          for (final row in rows)
            ContentCheckpoint(
              id: row.id,
              createdAt: row.createdAt,
              note: row.note,
            ),
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, LoadedContentCheckpoint>> getCheckpoint(
    String id,
    String checkpointId,
  ) async {
    await Future<void>.delayed(_latency);
    for (final row in _checkpoints[id] ?? const <LoadedContentCheckpoint>[]) {
      if (row.id == checkpointId) return Right(row);
    }
    return const Left(NotFoundFailure());
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(
    ContentSpec content, {
    String? checkpointNote,
  }) async {
    await Future<void>.delayed(_latency);
    if (store.find(content.id) == null) return const Left(NotFoundFailure());
    store.save(content);
    if (checkpointNote != null) {
      final now = DateTime.now();
      _checkpoints
          .putIfAbsent(content.id, () => [])
          .insert(
            0,
            LoadedContentCheckpoint(
              id: 'ckpt_${now.microsecondsSinceEpoch}',
              spec: content,
              createdAt: now,
              note: checkpointNote,
            ),
          );
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, PublicationState>> publish(
    String id, {
    String? note,
  }) async {
    await Future<void>.delayed(_latency);
    if (store.find(id) == null) return const Left(NotFoundFailure());
    store.publish(id, note: note);
    return Right(_publicationStateOf(id));
  }

  @override
  Future<Either<Failure, Unit>> unpublish(String id) async {
    await Future<void>.delayed(_latency);
    if (store.find(id) == null) return const Left(NotFoundFailure());
    store.unpublish(id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, ContentVersionsPage>> listVersions(
    String id, {
    String? cursor,
  }) async {
    await Future<void>.delayed(_latency);
    if (store.find(id) == null) return const Left(NotFoundFailure());

    final versions = store.versionsOf(id);
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final page = versions.skip(startIndex).take(_versionsPageLimit).toList();
    final endIndex = startIndex + page.length;
    final nextCursor = endIndex < versions.length ? '$endIndex' : null;

    return Right(
      ContentVersionsPage(
        items: [
          for (final meta in page)
            ContentVersion(
              version: meta.version,
              createdAt: meta.createdAt,
              note: meta.note,
              createdBy: meta.createdBy,
            ),
        ],
        nextCursor: nextCursor,
      ),
    );
  }

  @override
  Future<Either<Failure, LoadedContentVersion>> getVersion(
    String id,
    int version,
  ) async {
    await Future<void>.delayed(_latency);
    if (store.find(id) == null) return const Left(NotFoundFailure());

    final spec = store.specAtVersion(id, version);
    if (spec == null) return const Left(NotFoundFailure());

    FakeVersionMeta? meta;
    for (final candidate in store.versionsOf(id)) {
      if (candidate.version == version) {
        meta = candidate;
        break;
      }
    }
    if (meta == null) return const Left(NotFoundFailure());

    return Right(
      LoadedContentVersion(
        version: meta.version,
        spec: spec,
        createdAt: meta.createdAt,
        note: meta.note,
        createdBy: meta.createdBy,
      ),
    );
  }

  @override
  Future<Either<Failure, ContentSpec>> restoreVersion(
    String id,
    int version,
  ) async {
    await Future<void>.delayed(_latency);
    final spec = store.specAtVersion(id, version);
    if (spec == null) return const Left(NotFoundFailure());
    store.save(spec);
    return Right(spec);
  }

  PublicationState _publicationStateOf(String id) => PublicationState(
    publishedVersion: store.publishedVersionOf(id),
    publishedAt: store.publishedAtOf(id),
    hasUnpublishedChanges: store.hasUnpublishedChanges(id),
    latestVersion: store.latestVersionOf(id),
  );
}
