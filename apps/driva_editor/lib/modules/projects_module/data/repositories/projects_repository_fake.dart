import 'dart:convert' show base64Encode;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/projects_repository.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Mantém um
/// projeto de exemplo (id `default`, para casar com o `x-project-id` default
/// do app) e simula latência, como o fake de conteúdos.
class ProjectsRepositoryFake implements ProjectsRepository {
  static const _latency = Duration(milliseconds: 300);

  final Map<String, Project> _projects = {
    // Contagens coerentes com a seed dos outros fakes do projeto `default`:
    // `CategoriesRepositoryFake` nasce com 3 categorias ("Geral" + 2
    // subcategorias) e `FakeContentsStore`/`ContentsRepositoryFake` com 1
    // conteúdo de exemplo. Estático (não reflete criações/exclusões
    // subsequentes no fake) — os módulos são independentes por design; não
    // vale a pena acoplar `projects_module` ao estado de dev de outro módulo
    // só para um número exato numa fonte de dados que já é fake.
    'default': Project(
      id: 'default',
      title: 'Projeto Padrão',
      description: 'Projeto de exemplo criado automaticamente em dev.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      contentCount: 1,
      categoryCount: 3,
    ),
  };
  int _sequence = 1;

  @override
  Future<Either<Failure, List<Project>>> getProjects({
    bool archived = false,
  }) async {
    await Future<void>.delayed(_latency);
    final projects =
        _projects.values.where((p) => p.isArchived == archived).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Right(projects);
  }

  @override
  Future<Either<Failure, Project>> getProject(String id) async {
    await Future<void>.delayed(_latency);
    final project = _projects[id];
    if (project == null) return const Left(NotFoundFailure());
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> createProject({
    required String title,
    String? description,
    ProjectImageInput? image,
  }) async {
    await Future<void>.delayed(_latency);
    final id = 'proj_fake_${_sequence++}';
    final now = DateTime.now();
    final project = Project(
      id: id,
      title: title,
      description: description,
      // Fake não tem storage: simula uma imagem "servida" via data URI só
      // para o card não ficar sem preview quando o usuário testa o upload.
      imageUrl: image != null ? _dataUrlFrom(image) : null,
      createdAt: now,
      updatedAt: now,
      // Projeto recém-criado no fake nasce sem conteúdos/categorias
      // (o backend real semeia a "Geral" na mesma transação — o fake não
      // reproduz isso, é só para o fluxo de criação exercitar a UI).
      contentCount: 0,
      categoryCount: 0,
    );
    _projects[id] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> updateProject(
    String id, {
    String? title,
    String? description,
    ProjectImageInput? image,
    bool removeImage = false,
  }) async {
    await Future<void>.delayed(_latency);
    final current = _projects[id];
    if (current == null) return const Left(NotFoundFailure());
    final updated = current.copyWith(
      title: title,
      updatedAt: DateTime.now(),
      description: description != null ? () => description : null,
      imageUrl: removeImage
          ? () => null
          : (image != null ? () => _dataUrlFrom(image) : null),
    );
    _projects[id] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, Project>> archiveProject(String id) async {
    await Future<void>.delayed(_latency);
    final current = _projects[id];
    if (current == null) return const Left(NotFoundFailure());
    final updated = current.copyWith(archivedAt: () => DateTime.now());
    _projects[id] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, Project>> unarchiveProject(String id) async {
    await Future<void>.delayed(_latency);
    final current = _projects[id];
    if (current == null) return const Left(NotFoundFailure());
    final updated = current.copyWith(archivedAt: () => null);
    _projects[id] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, Unit>> deleteProject(String id) async {
    await Future<void>.delayed(_latency);
    final current = _projects[id];
    if (current == null) return const Left(NotFoundFailure());
    // Espelha a regra do backend: exclusão definitiva só é permitida com o
    // projeto já arquivado.
    if (!current.isArchived) {
      return const Left(
        ConflictFailure(
          message:
              'Só é possível apagar definitivamente um projeto arquivado. '
              'Arquive o projeto antes de excluí-lo.',
        ),
      );
    }
    _projects.remove(id);
    return const Right(unit);
  }

  String _dataUrlFrom(ProjectImageInput image) {
    // Preview local só: não é uma URL servível de verdade, mas o
    // `Image.network`/`NetworkImage` do Flutter Web resolve `data:` URIs.
    final base64 = _base64(image.bytes);
    final contentType = image.contentType ?? 'image/png';
    return 'data:$contentType;base64,$base64';
  }

  String _base64(List<int> bytes) => base64Encode(bytes);
}
