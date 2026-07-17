import 'package:dio/dio.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/data/models/models.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  ProjectsRepositoryImpl(this.dio);
  final Dio dio;

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

  /// No Flutter Web a `imageUrl` relativa resolveria contra a origem do front
  /// (nginx), não da API → 404. `v=<updatedAt>` é cache-buster: a URL de
  /// serving é estável, sem ele a capa trocada serviria a versão em cache.
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
