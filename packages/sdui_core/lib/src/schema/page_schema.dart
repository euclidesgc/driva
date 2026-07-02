import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../model/page_spec.dart';
import 'node_schema.dart';
import 'spec_validation_error.dart';
import 'spec_version.dart';

// Envelope da página. O `root` é validado à parte por `parseNode`.
final _pageEnvelope = z.map({
  'specVersion': z.int(),
  'kind': z.$enum(['page']),
  'id': z.string().min(1),
  'name': z.string().min(1),
  'screenTarget': z.string().min(1),
});

/// A única porta JSON → entidade do spec de página.
///
/// Valida o envelope (zard), a versão do formato, e a árvore de nós
/// (recursiva, contra o catálogo). `root` precisa ser um `column`: os blocos
/// de topo da página são `root.children`.
Either<SpecValidationError, PageSpec> parsePageSpec(Map<String, dynamic> json) {
  final result = _pageEnvelope.safeParse(json);
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
      PageSpec(
        specVersion: specVersion,
        id: data['id'] as String,
        name: data['name'] as String,
        screenTarget: data['screenTarget'] as String,
        root: root,
      ),
    );
  });
}
