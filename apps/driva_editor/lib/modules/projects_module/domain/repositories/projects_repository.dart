import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/entities.dart';

/// Contrato do CRUD de projetos. O erro previsto mora na assinatura.
///
/// A imagem entra como [ProjectImageInput] (bytes + metadados, Dart puro) —
/// a implementação (camada `data`) é quem monta o `multipart/form-data`
/// contra `/v1/projects`.
abstract interface class ProjectsRepository {
  /// `archived: false` (default) lista os ativos; `true` lista os
  /// arquivados. Dois conjuntos disjuntos — nunca misturados numa resposta.
  Future<Either<Failure, List<Project>>> getProjects({bool archived = false});

  Future<Either<Failure, Project>> getProject(String id);

  Future<Either<Failure, Project>> createProject({
    required String title,
    String? description,
    ProjectImageInput? image,
  });

  /// Atualiza só os campos enviados. `image` presente substitui a imagem
  /// atual; `removeImage: true` zera a imagem sem enviar outra (os dois
  /// juntos não fazem sentido — a regra de exclusividade é do use case).
  Future<Either<Failure, Project>> updateProject(
    String id, {
    String? title,
    String? description,
    ProjectImageInput? image,
    bool removeImage = false,
  });

  /// Exclusão lógica: seta `archivedAt`. O projeto some da home mas
  /// continua existindo (aparece na área de Arquivados).
  Future<Either<Failure, Project>> archiveProject(String id);

  /// Reverte o arquivamento: `archivedAt` volta a `null`.
  Future<Either<Failure, Project>> unarchiveProject(String id);

  /// Exclusão física (cascade total). Só válida para projeto arquivado —
  /// projeto ativo devolve `ConflictFailure`.
  Future<Either<Failure, Unit>> deleteProject(String id);
}
