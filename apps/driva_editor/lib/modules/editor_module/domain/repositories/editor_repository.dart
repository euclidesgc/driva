import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

abstract interface class EditorRepository {
  Future<Either<Failure, LoadedContent>> loadContent(String id);

  Future<Either<Failure, Unit>> saveDraft(ContentSpec content);

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
