import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

abstract interface class EditorRepository {
  Future<Either<Failure, LoadedContent>> loadContent(String id);

  /// [checkpointNote] presente marca um ponto no histórico junto do save — o
  /// "commit" do editor. Salvar continua não publicando: só publicar cria
  /// versão, e o ponto marcado aqui nunca vai ao ar.
  Future<Either<Failure, Unit>> saveDraft(
    ContentSpec content, {
    String? checkpointNote,
  });

  /// Os pontos de trabalho marcados ao salvar. Paginados por data, não por
  /// número: checkpoint não consome `vN`.
  Future<Either<Failure, ContentCheckpointsPage>> listCheckpoints(
    String id, {
    String? cursor,
  });

  Future<Either<Failure, LoadedContentCheckpoint>> getCheckpoint(
    String id,
    String checkpointId,
  );

  Future<Either<Failure, PublicationState>> publish(String id, {String? note});

  Future<Either<Failure, Unit>> unpublish(String id);

  Future<Either<Failure, ContentVersionsPage>> listVersions(
    String id, {
    String? cursor,
  });

  Future<Either<Failure, LoadedContentVersion>> getVersion(
    String id,
    int version,
  );

  Future<Either<Failure, ContentSpec>> restoreVersion(String id, int version);
}
