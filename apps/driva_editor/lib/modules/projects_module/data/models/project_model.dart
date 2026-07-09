import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.imageUrl,
  });

  // A forma esperada do item de `GET /v1/projects` e do detalhe
  // (`GET/POST/PUT /v1/projects/:id`), declarada uma vez. Sem `slug`
  // (decisão travada no PRD). Atenção: o backend serve `imageUrl` (URL
  // servível), NUNCA `imageKey` (detalhe interno de storage) — o model só
  // conhece `imageUrl`, nullable quando o projeto não tem imagem.
  //
  // `createdAt` obrigatório em ambos os payloads (lista e detalhe) por
  // decisão VR-01 (variance_report.md): lista e detalhe têm a mesma
  // forma, alinhado ao `required` da entidade `Project` (domain/F3).
  static final _schema = z.map({
    'id': z.string().min(1),
    'title': z.string().min(1),
    'description': z.string().optional(),
    'imageUrl': z.string().nullable().optional(),
    'createdAt': z.date(),
    'updatedAt': z.date(),
  });

  /// Valida e converte. Payload inválido vira `ValidationFailure` descritiva,
  /// nunca um cast cru estourando.
  static Either<Failure, ProjectModel> tryParse(Map<String, dynamic> map) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      ProjectModel(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String?,
        imageUrl: data['imageUrl'] as String?,
        createdAt: data['createdAt'] as DateTime,
        updatedAt: data['updatedAt'] as DateTime,
      ),
    );
  }
}
