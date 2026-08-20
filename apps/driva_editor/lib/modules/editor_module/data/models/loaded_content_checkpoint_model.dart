import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:zard/zard.dart';

class LoadedContentCheckpointModel extends LoadedContentCheckpoint {
  const LoadedContentCheckpointModel({
    required super.id,
    required super.spec,
    required super.createdAt,
    super.note,
    super.createdBy,
  });

  static final ZMap _envelopeSchema = z.map({
    'id': z.string(),
    'spec': z.map({}),
    'createdAt': z.date(),
    'note': z.string().optional(),
    'createdBy': z.string().optional(),
  });

  static Either<Failure, LoadedContentCheckpointModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }
    final data = envelope.data!;

    // `z.map({})` só confirma que `spec` é um Map — o conteúdo de verdade vem
    // do `map` bruto, como em `LoadedContentVersionModel`.
    final parsedSpec = parseContentSpec(
      (map['spec'] as Map).cast<String, dynamic>(),
    ).mapLeft<Failure>((error) => ValidationFailure(error.message));

    return parsedSpec.map(
      (spec) => LoadedContentCheckpointModel(
        id: data['id'] as String,
        spec: spec,
        createdAt: data['createdAt'] as DateTime,
        note: data['note'] as String?,
        createdBy: data['createdBy'] as String?,
      ),
    );
  }
}
