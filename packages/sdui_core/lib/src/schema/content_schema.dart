import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../model/content_spec.dart';
import '../model/sdui_node.dart';
import 'node_schema.dart';
import 'spec_validation_error.dart';
import 'spec_version.dart';

final _contentEnvelope = z.map({
  'specVersion': z.int(),
  'kind': z.$enum(['content']),
  'id': z.string().min(1),
  'name': z.string().min(1),
  'slug': z.string().regex(RegExp(r'^[a-z][a-z0-9-]*$')),
  'description': z.string().optional(),
});

Either<SpecValidationError, ContentSpec> parseContentSpec(
  Map<String, dynamic> json,
) {
  final result = _contentEnvelope.safeParse(json);
  if (!result.success) {
    return Left(SpecValidationError(z.prettifyError(result.error!)));
  }
  final data = result.data!;

  final specVersion = data['specVersion'] as int;
  if (specVersion != kSpecVersion) {
    return Left(
      SpecValidationError(
        'specVersion $specVersion não suportada (atual: $kSpecVersion)',
      ),
    );
  }

  ContentSpec build(SduiNode? root) => ContentSpec(
    specVersion: specVersion,
    id: data['id'] as String,
    name: data['name'] as String,
    slug: data['slug'] as String,
    description: data['description'] as String?,
    root: root,
  );

  final rawRoot = json['root'];
  if (rawRoot == null) {
    return Right(build(null));
  }
  if (rawRoot is! Map) {
    return const Left(SpecValidationError('root: esperado um objeto'));
  }

  return parseNode(rawRoot.cast<String, dynamic>()).map(build);
}
