import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/projects_repository.dart';
import '../models/models.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final Dio dio;
  ProjectsRepositoryImpl(this.dio); // o Dio compartilhado, injetado

  @override
  Future<Either<Failure, List<Project>>> getProjects({
    bool archived = false,
  }) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '/v1/projects',
        queryParameters: {'status': archived ? 'archived' : 'active'},
      );
      final raw = (response.data ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      final projects = <Project>[];
      for (final map in raw) {
        final parsed = ProjectModel.tryParse(map);
        if (parsed.isLeft()) {
          return parsed.map((_) => <Project>[]);
        }
        projects.add(_resolveImageUrl(parsed.getRight().toNullable()!));
      }
      return Right(projects);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Project>> getProject(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/v1/projects/$id');
      return ProjectModel.tryParse(
        response.data ?? const {},
      ).map(_resolveImageUrl);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Project>> createProject({
    required String title,
    String? description,
    ProjectImageInput? image,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'description': ?description,
        if (image != null) 'image': _multipartFrom(image),
      });
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/projects',
        data: formData,
      );
      return ProjectModel.tryParse(
        response.data ?? const {},
      ).map(_resolveImageUrl);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject(
    String id, {
    String? title,
    String? description,
    ProjectImageInput? image,
    bool removeImage = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': ?title,
        'description': ?description,
        if (image != null) 'image': _multipartFrom(image),
        if (removeImage) 'removeImage': 'true',
      });
      final response = await dio.put<Map<String, dynamic>>(
        '/v1/projects/$id',
        data: formData,
      );
      return ProjectModel.tryParse(
        response.data ?? const {},
      ).map(_resolveImageUrl);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Project>> archiveProject(String id) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/projects/$id/archive',
      );
      return ProjectModel.tryParse(
        response.data ?? const {},
      ).map(_resolveImageUrl);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Project>> unarchiveProject(String id) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/projects/$id/unarchive',
      );
      return ProjectModel.tryParse(
        response.data ?? const {},
      ).map(_resolveImageUrl);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProject(String id) async {
    try {
      await dio.delete<void>('/v1/projects/$id');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  /// A API devolve `imageUrl` **relativa** (`/v1/projects/:id/image`). No
  /// Flutter Web, uma URL relativa resolveria contra a origem do FRONT (nginx),
  /// não da API — o `Image.network` bateria em `https://<front>/v1/...` → 404,
  /// e o card cairia no gradiente (parecia "imagem não persistida"). Aqui, na
  /// fronteira HTTP, resolvemos para absoluta usando a base do próprio Dio,
  /// para a entidade carregar uma URL de fato servível. Idempotente: URL já
  /// absoluta (ou nula/vazia) passa intacta.
  ///
  /// A URL de serving é **estável** (`/v1/projects/:id/image`), então trocar a
  /// capa não muda a URL e o `Image.network` do Flutter Web serviria a versão
  /// antiga do cache. Anexamos `v=<updatedAt>` como cache-buster: o `updatedAt`
  /// muda a cada escrita do projeto, então a URL só muda quando o projeto muda,
  /// forçando o refetch da nova imagem sem quebrar cache quando nada mudou.
  Project _resolveImageUrl(Project project) {
    final url = project.imageUrl;
    if (url == null || url.isEmpty || url.startsWith('http')) return project;
    final base = dio.options.baseUrl;
    final trimmedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final path = url.startsWith('/') ? url : '/$url';
    final version = project.updatedAt.millisecondsSinceEpoch;
    return project.copyWith(imageUrl: () => '$trimmedBase$path?v=$version');
  }

  MultipartFile _multipartFrom(ProjectImageInput image) {
    return MultipartFile.fromBytes(
      image.bytes,
      filename: image.filename,
      contentType: image.contentType != null
          ? DioMediaType.parse(image.contentType!)
          : null,
    );
  }

  // O único try/catch do módulo mora nesta classe: HTTP vira Failure aqui.
  // Projeto não tem slug — o 409 aqui é conflito de estado do próprio
  // arquivamento: exclusão definitiva (`DELETE`) só é permitida com o
  // projeto já arquivado; tentar em um projeto ativo devolve 409. Reusa
  // `ConflictFailure` com uma mensagem própria (sem `suggestedSlug`, que é
  // específico de conteúdo) em vez de generalizar o core. Quando o backend
  // manda uma mensagem própria no corpo, ela prevalece sobre o default.
  Failure _failureFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      404 => const NotFoundFailure(),
      409 => switch (_messageFrom(e.response?.data)) {
        final String message => ConflictFailure(message: message),
        null => const ConflictFailure(
          message:
              'Só é possível apagar definitivamente um projeto arquivado. '
              'Arquive o projeto antes de excluí-lo.',
        ),
      },
      400 => switch (_messageFrom(e.response?.data)) {
        final String message => ValidationFailure(message),
        null => const ValidationFailure(),
      },
      413 => const ValidationFailure(
        'A imagem enviada excede o tamanho máximo permitido.',
      ),
      _ => const UnexpectedFailure(),
    },
    _ => const UnexpectedFailure(),
  };

  /// Extrai uma mensagem de erro do corpo do 400, quando o backend a
  /// oferece (Nest/class-validator costuma mandar `message`). Ausente →
  /// mensagem default do `ValidationFailure`.
  String? _messageFrom(dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (body is Map && body['message'] is List) {
      final messages = body['message'] as List;
      if (messages.isNotEmpty) return messages.join(' ');
    }
    return null;
  }
}
