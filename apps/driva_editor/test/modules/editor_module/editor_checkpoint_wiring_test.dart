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
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/editor_page.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/checkpoint_row.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_history_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_header.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:driva_editor/modules/projects_module/domain/use_cases/get_project_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProjectsRepository extends Mock implements ProjectsRepository {}

class _MockEditorLayoutRepository extends Mock
    implements EditorLayoutRepository {}

/// Prova a fiação ponta a ponta do item 53: `GetContentCheckpointUseCase`
/// resolvido só em `EditorPage.pageBuilder` chegando até `VersionHistoryDialog`
/// e as três ações de um ponto salvo funcionando de verdade, na árvore real
/// montada a partir da rota do editor — não um harness sintético que já
/// monta os widgets soltos com o use case passado à mão.
///
/// O checkpoint nasce por uma chamada direta ao repositório fake (o mesmo
/// que o app usa), não pela UI de "Salvar e marcar": a existência do ponto
/// salvo é o cenário, não o que este teste prova.
void main() {
  const projectId = 'proj_1';
  const contentId = 'ct_exemplo';
  const checkpointNote = 'Antes do lançamento';

  final project = Project(
    id: projectId,
    title: 'Projeto',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
    contentCount: 1,
    categoryCount: 1,
  );

  setUp(() async {
    final store = FakeContentsStore();
    final repository = EditorRepositoryFake(store);
    final seed = store.find(contentId)!;
    await repository.saveDraft(seed, checkpointNote: checkpointNote);

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
        const AppConfig(
          environment: 'test',
          apiBaseUrl: 'https://api.test',
          defaultProjectId: projectId,
          useFakeData: true,
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
  });

  tearDown(getIt.reset);

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/projects/$projectId/contents/$contentId/edit',
      routes: [
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

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Histórico'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GetContentCheckpointUseCase chega do getIt até VersionHistoryDialog',
    (tester) async {
      await pumpEditor(tester);
      await openHistory(tester);

      final dialog = tester.widget<VersionHistoryDialog>(
        find.byType(VersionHistoryDialog),
      );
      expect(
        dialog.getContentCheckpointUseCase,
        isNotNull,
        reason:
            'sem ele chegando aqui, as três ações de um ponto salvo '
            'resolveriam vazias em silêncio — o mesmo bug já visto neste item',
      );
    },
  );

  testWidgets(
    'na árvore real, a linha do ponto salvo chega com as três ações '
    'habilitadas — não são botões inertes',
    (tester) async {
      await pumpEditor(tester);
      await openHistory(tester);

      expect(find.byType(CheckpointRow), findsOneWidget);
      expect(find.text(checkpointNote), findsOneWidget);

      final ver = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ver'),
      );
      final comparar = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Comparar'),
      );
      final carregar = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
      );
      expect(ver.onPressed, isNotNull);
      expect(comparar.onPressed, isNotNull);
      expect(carregar.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Ver, na árvore real, abre a revisão com o cabeçalho do ponto salvo',
    (tester) async {
      await pumpEditor(tester);
      await openHistory(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Ver'));
      await tester.pumpAndSettle();

      expect(find.byType(VersionReviewHeader), findsOneWidget);
      expect(find.text('Somente leitura'), findsOneWidget);
    },
  );

  testWidgets(
    'Carregar no rascunho, na árvore real, escreve o spec do ponto salvo '
    'e marca o documento como não publicado',
    (tester) async {
      await pumpEditor(tester);
      await openHistory(tester);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Carregar o ponto salvo "$checkpointNote'),
        findsOneWidget,
        reason: 'a confirmação nomeia o ponto salvo, nunca "versão"',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VersionHistoryDialog), findsNothing);
      final editorCubit = tester
          .element(find.byType(EditorPage))
          .read<EditorCubit>();
      final state = editorCubit.state as EditorReady;
      expect(state.saveStatus, SaveStatus.dirty);
      expect(state.publication.hasUnpublishedChanges, isTrue);
    },
  );
}
