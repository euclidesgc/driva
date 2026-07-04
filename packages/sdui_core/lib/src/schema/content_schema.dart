import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../model/content_spec.dart';
import 'node_schema.dart';
import 'spec_validation_error.dart';
import 'spec_version.dart';

// Envelope do conteúdo. O `root` é validado à parte por `parseNode`.
final _contentEnvelope = z.map({
  'specVersion': z.int(),
  'kind': z.$enum(['content']),
  'id': z.string().min(1),
  'name': z.string().min(1),
  'slug': z.string().regex(RegExp(r'^[a-z][a-z0-9-]*$')),
  'description': z.string().optional(),
});

/// A única porta JSON → entidade do spec de conteúdo.
///
/// Valida o envelope (zard), a versão do formato, e a árvore de nós
/// (recursiva, contra o catálogo). `root` precisa ser um `column`: os blocos
/// de topo do conteúdo são `root.children`.
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

  final rawRoot = json['root'];
  if (rawRoot is! Map) {
    return const Left(SpecValidationError('root: esperado um objeto'));
  }

  return parseNode(rawRoot.cast<String, dynamic>()).flatMap((root) {
    if (root.type != 'column') {
      return Left(
        SpecValidationError('root: precisa ser "column" (veio "${root.type}")'),
      );
    }
    return Right(
      ContentSpec(
        specVersion: specVersion,
        id: data['id'] as String,
        name: data['name'] as String,
        slug: data['slug'] as String,
        description: data['description'] as String?,
        root: root,
      ),
    );
  });
}
