import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/published_content.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:zard/zard.dart';

/// Envelope de `GET /v1/public/projects/:projectId/contents/:slug`. O envelope
/// é da API; o `spec` é do kernel — quem o valida é `parseContentSpec`, o
/// único portão de entrada de spec do sistema.
class PublishedContentModel {
  const PublishedContentModel._();

  static final ZMap _envelopeSchema = z.map({
    'id': z.string().min(1),
    'name': z.string().min(1),
    'slug': z.string().min(1),
    'updatedAt': z.date(),
    'spec': z.map({}),
  });

  static Either<Failure, PublishedContent> tryParse(
    Map<String, dynamic> map, {
    String? etag,
  }) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }

    final rawSpec = map['spec'];
    if (rawSpec is! Map) {
      return const Left(ValidationFailure('spec: esperado um objeto'));
    }

    return parseContentSpec(Map<String, dynamic>.from(rawSpec)).match(
      (error) => Left(ValidationFailure(error.message)),
      (spec) => Right(
        PublishedContent(
          spec: spec,
          updatedAt: envelope.data!['updatedAt'] as DateTime,
          etag: etag,
        ),
      ),
    );
  }
}
