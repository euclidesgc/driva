import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/safe_area_descriptor.dart';
import 'package:sdui_core/src/model/content_spec.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/schema/node_props_schema.dart';
import 'package:sdui_core/src/schema/node_schema.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:sdui_core/src/schema/spec_version.dart';
import 'package:zard/zard.dart';

final ZMap _contentEnvelope = z.map({
  'specVersion': z.int(),
  'kind': z.$enum(['content']),
  'id': z.string().min(1),
  'name': z.string().min(1),
  'slug': z.string().regex(RegExp(r'^[a-z][a-z0-9-]*$')),
  'description': z.string().optional(),
});

Either<SpecValidationError, ContentSpec> parseContentSpec(
  Map<String, dynamic> json, {
  bool tolerant = false,
}) {
  final result = _contentEnvelope.safeParse(json);
  if (!result.success) {
    return Left(SpecValidationError(z.prettifyError(result.error!)));
  }
  final data = result.data!;

  final specVersion = data['specVersion'] as int;
  if (specVersion < kOldestSpecVersion || specVersion > kLatestSpecVersion) {
    return Left(
      SpecValidationError(
        'specVersion $specVersion não suportada '
        '(suportadas: $kOldestSpecVersion a $kLatestSpecVersion)',
      ),
    );
  }

  final rawSafeArea = json['safeArea'];
  if (rawSafeArea != null && rawSafeArea is! Map) {
    return const Left(SpecValidationError('safeArea: esperado um objeto'));
  }
  if (rawSafeArea is Map) {
    final validated = validateNodeProps(
      rawSafeArea.cast<String, dynamic>(),
      safeAreaDescriptor,
      path: 'safeArea',
      specVersion: specVersion,
      context: BindingContext.page,
      tolerant: tolerant,
    );
    if (validated case Left(:final value)) return Left(value);
  }

  ContentSpec build(SduiNode? root) => ContentSpec(
    specVersion: specVersion,
    id: data['id'] as String,
    name: data['name'] as String,
    slug: data['slug'] as String,
    description: data['description'] as String?,
    root: root,
    safeArea: (rawSafeArea as Map?)?.cast<String, dynamic>() ?? const {},
  );

  final rawRoot = json['root'];
  if (rawRoot == null) {
    return Right(build(null));
  }
  if (rawRoot is! Map) {
    return const Left(SpecValidationError('root: esperado um objeto'));
  }

  return parseNode(
    rawRoot.cast<String, dynamic>(),
    specVersion: specVersion,
    tolerant: tolerant,
  ).map(build);
}
