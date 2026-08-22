import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/network/network.dart';
import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/editor_module/data/repositories/editor_repository_fake.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/repositories.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/editor_routes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog.dart';
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

/// Prova a fiação ponta a ponta do item 51: `AppConfig.demoApkUrl` resolvido
/// só em `EditorPage.pageBuilder` chegando até `PreviewShareDialog` na árvore
/// real montada a partir da rota do editor — não um harness sintético que já
/// monta o diálogo solto com o valor passado à mão.
void main() {
  const projectId = 'proj_1';
  const contentId = 'ct_exemplo';

  final project = Project(
    id: projectId,
    title: 'Projeto',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
    contentCount: 1,
    categoryCount: 1,
  );

  void registerCommonFakes(String demoApkUrl) {
    final store = FakeContentsStore();
    final repository = EditorRepositoryFake(store);

    final projectsRepository = _MockProjectsRepository();
    when(
      () => projectsRepository.getProject(any()),
    ).thenAnswer((_) async => Right(project));

    final layoutRepository = _MockEditorLayoutRepository();
    when(
      layoutRepository.getLayout,
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    getIt
      ..registerSingleton<AppConfig>(
        AppConfig(
          environment: 'test',
          apiBaseUrl: 'https://api.test',
          defaultProjectId: projectId,
          useFakeData: true,
          demoApkUrl: demoApkUrl,
        ),
      )
      ..registerSingleton<ProjectScope>(
        ProjectScope(initialProjectId: projectId),
      )
      ..registerSingleton<EditorRepository>(repository)
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
        () =>
            GetContentCheckpointsUseCase(repository: getIt<EditorRepository>()),
      )
      ..registerFactory(
        () =>
            GetContentCheckpointUseCase(repository: getIt<EditorRepository>()),
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
  }

  tearDown(getIt.reset);

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/projects/$projectId/contents/$contentId/edit',
      routes: [
        EditorRoutes.previewRoute,
        ShellRoute(
          builder: (context, state, child) => AppShell(
            homeRouteName: 'home',
            themeButton: const SizedBox.shrink(),
            child: child,
          ),
          routes: [EditorRoutes.route],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPreviewDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Ver no celular'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'AppConfig.demoApkUrl chega, pela rota real, ao PreviewShareDialog',
    (tester) async {
      registerCommonFakes('https://exemplo.test/driva-demo-hml.apk');
      await pumpEditor(tester);
      await openPreviewDialog(tester);

      final dialog = tester.widget<PreviewShareDialog>(
        find.byType(PreviewShareDialog),
      );
      expect(
        dialog.demoApkUrl,
        'https://exemplo.test/driva-demo-hml.apk',
        reason:
            'sem ele chegando aqui, o bloco de download resolveria vazio '
            'em silêncio, mesmo com a URL configurada no AppConfig',
      );
      expect(find.text('Baixar APK de teste'), findsOneWidget);
    },
  );

  testWidgets(
    'sem URL configurada no AppConfig, o bloco de download não aparece',
    (tester) async {
      registerCommonFakes('');
      await pumpEditor(tester);
      await openPreviewDialog(tester);

      expect(find.byType(PreviewShareDialog), findsOneWidget);
      expect(find.byType(DemoApkDownloadBlock), findsNothing);
      expect(find.text('Baixar APK de teste'), findsNothing);
    },
  );
}
