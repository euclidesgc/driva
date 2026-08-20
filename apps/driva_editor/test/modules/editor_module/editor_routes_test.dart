import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/network/network.dart';
import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/editor_module/data/repositories/editor_repository_impl.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/repositories.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/editor_routes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/editor_page.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/invalid_content_screen.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:driva_editor/modules/projects_module/domain/use_cases/get_project_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProjectsRepository extends Mock implements ProjectsRepository {}

class _MockEditorLayoutRepository extends Mock
    implements EditorLayoutRepository {}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(const {'message': 'não encontrado'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const bootProjectId = 'default';
  const urlProjectId = 'proj_da_url';
  const contentId = 'ct_1';

  final project = Project(
    id: urlProjectId,
    title: 'Projeto da URL',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
    contentCount: 1,
    categoryCount: 1,
  );

  late ProjectScope scope;
  late _RecordingAdapter adapter;

  setUp(() {
    scope = ProjectScope(initialProjectId: bootProjectId);
    adapter = _RecordingAdapter();

    const config = AppConfig(
      environment: 'test',
      apiBaseUrl: 'https://api.test',
      defaultProjectId: bootProjectId,
      useFakeData: false,
    );

    final dio = createDio(config, scope)
      ..interceptors.removeWhere((interceptor) => interceptor is LogInterceptor)
      ..httpClientAdapter = adapter;

    final projectsRepository = _MockProjectsRepository();
    when(
      () => projectsRepository.getProject(any()),
    ).thenAnswer((_) async => Right(project));

    final layoutRepository = _MockEditorLayoutRepository();
    when(
      layoutRepository.getLayout,
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final editorRepository = EditorRepositoryImpl(dio);

    getIt
      ..registerSingleton<AppConfig>(config)
      ..registerSingleton<ProjectScope>(scope)
      ..registerSingleton<EditorRepository>(editorRepository)
      ..registerSingleton<EditorLayoutRepository>(layoutRepository)
      ..registerSingleton<ProjectsRepository>(projectsRepository)
      ..registerFactory(
        () => LoadContentUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () => SaveDraftUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () => PublishContentUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () => UnpublishContentUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () =>
            RestoreContentVersionUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () => GetContentVersionsUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () => GetContentVersionUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () => GetEditorLayoutUseCase(
          repository: getIt<EditorLayoutRepository>(),
        ),
      )
      ..registerFactory(
        () => SaveEditorLayoutUseCase(
          repository: getIt<EditorLayoutRepository>(),
        ),
      )
      ..registerFactory(
        () => GetProjectUseCase(repository: getIt<ProjectsRepository>()),
      );
  });

  tearDown(getIt.reset);

  Future<void> pumpAt(WidgetTester tester, String location, {GoRoute? route}) {
    final router = GoRouter(
      initialLocation: location,
      routes: [route ?? EditorRoutes.route],
    );
    addTearDown(router.dispose);
    return tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  group('rota do editor com o projeto no path', () {
    testWidgets(
      'a primeira requisição já sai com o x-project-id da URL, não com o '
      'do boot',
      (tester) async {
        await pumpAt(
          tester,
          '/projects/$urlProjectId/contents/$contentId/edit',
        );
        await tester.pumpAndSettle();

        expect(adapter.requests, isNotEmpty);
        final first = adapter.requests.first;
        expect(first.path, '/v1/contents/$contentId');
        expect(first.headers['x-project-id'], urlProjectId);
        expect(first.headers['x-project-id'], isNot(bootProjectId));
      },
    );

    testWidgets('todas as requisições da carga carregam o projeto da URL', (
      tester,
    ) async {
      await pumpAt(tester, '/projects/$urlProjectId/contents/$contentId/edit');
      await tester.pumpAndSettle();

      expect(
        adapter.requests.map((request) => request.headers['x-project-id']),
        everyElement(urlProjectId),
      );
    });
  });

  group('guarda de path param', () {
    testWidgets('rota sem o segmento do projeto para na tela de inválido', (
      tester,
    ) async {
      await pumpAt(
        tester,
        '/contents/$contentId/edit',
        route: GoRoute(
          path: '/contents/:id/edit',
          builder: EditorPage.pageBuilder,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InvalidContentScreen), findsOneWidget);
      expect(find.byType(EditorPage), findsNothing);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('projeto em branco no path não vira editor nem escopo novo', (
      tester,
    ) async {
      await pumpAt(tester, '/projects/%20/contents/$contentId/edit');
      await tester.pumpAndSettle();

      expect(find.byType(InvalidContentScreen), findsOneWidget);
      expect(find.byType(EditorPage), findsNothing);
      expect(scope.projectId, bootProjectId);
    });
  });
}
