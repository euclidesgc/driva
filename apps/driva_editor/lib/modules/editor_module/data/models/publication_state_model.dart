import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

/// `publishedVersion` é `{version, publishedAt} | null` no envelope — o
/// `z.map` do envelope só confirma presença/tipo; o objeto aninhado, quando
/// existe, é revalidado pelo schema próprio (mesmo padrão de
/// `ContentVersionsPageModel`).
class PublicationStateModel extends PublicationState {
  const PublicationStateModel({
    required super.hasUnpublishedChanges,
    super.publishedVersion,
    super.publishedAt,
  });

  static final ZMap _envelopeSchema = z.map({
    'hasUnpublishedChanges': z.bool(),
    'publishedVersion': z.map({}).nullable().optional(),
  });

  static final ZMap _publishedVersionSchema = z.map({
    'version': z.int(),
    'publishedAt': z.date(),
  });

  static Either<Failure, PublicationStateModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }
    final hasUnpublishedChanges =
        envelope.data!['hasUnpublishedChanges'] as bool;

    final rawPublishedVersion = map['publishedVersion'];
    if (rawPublishedVersion == null) {
      return Right(
        PublicationStateModel(hasUnpublishedChanges: hasUnpublishedChanges),
      );
    }

    final versionResult = _publishedVersionSchema.safeParse(
      (rawPublishedVersion as Map).cast<String, dynamic>(),
    );
    if (!versionResult.success) {
      return Left(ValidationFailure(z.prettifyError(versionResult.error!)));
    }
    final versionData = versionResult.data!;
    return Right(
      PublicationStateModel(
        publishedVersion: versionData['version'] as int,
        publishedAt: versionData['publishedAt'] as DateTime,
        hasUnpublishedChanges: hasUnpublishedChanges,
      ),
    );
  }
}
