import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:zard/zard.dart';

class LoadedContentVersionModel extends LoadedContentVersion {
  const LoadedContentVersionModel({
    required super.version,
    required super.spec,
    required super.createdAt,
    super.note,
    super.createdBy,
  });

  static final ZMap _envelopeSchema = z.map({
    'version': z.int(),
    'spec': z.map({}),
    'createdAt': z.date(),
    'note': z.string().optional(),
    'createdBy': z.string().optional(),
  });

  static Either<Failure, LoadedContentVersionModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }
    final data = envelope.data!;

    // `z.map({})` só confirma que `spec` é um Map — sem sub-schema, o
    // `parseInto` devolve `{}` (mesmo padrão de `ContentVersionsPageModel`
    // e `PublicationStateModel`), então o conteúdo de verdade vem do `map`
    // bruto de entrada, não de `envelope.data!`.
    final parsedSpec = parseContentSpec(
      (map['spec'] as Map).cast<String, dynamic>(),
    ).mapLeft<Failure>((error) => ValidationFailure(error.message));

    return parsedSpec.map(
      (spec) => LoadedContentVersionModel(
        version: data['version'] as int,
        spec: spec,
        createdAt: data['createdAt'] as DateTime,
        note: data['note'] as String?,
        createdBy: data['createdBy'] as String?,
      ),
    );
  }
}
