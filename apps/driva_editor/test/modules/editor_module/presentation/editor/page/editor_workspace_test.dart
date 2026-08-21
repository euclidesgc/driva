import 'dart:ui' show Tristate;

import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail_button.dart';
import 'package:driva_editor/core/widgets/layout/resize_handle.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/editor_page.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/center_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_workspace.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/right_panel_rail.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_draft_legend.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_candidate_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/editor_status_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/checkpoint_row.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../support/app_fonts.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class _MockPublishContentUseCase extends Mock
    implements PublishContentUseCase {}

class _MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class _MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

class _MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

class _MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class _MockGetContentCheckpointsUseCase extends Mock
    implements GetContentCheckpointsUseCase {}

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

ContentSpec _docWithText(String text) => ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [
      SduiNode(id: 'nd_text', type: 'text', properties: {'data': text}),
    ],
  ),
);

/// `spacer` como raiz (fora de `row`/`column`) dispara
/// `DiagnosticCode.flexOnlyOutsideFlex` — o mesmo diagnóstico que
/// `EditorStatusBar` mostra no rodapé (P2, aceite 34).
const ContentSpec _docWithError = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(id: 'nd_root', type: 'spacer'),
);

void main() {
  late EditorCubit cubit;
  late _MockThemeCubit themeCubit;
  late EditorLayoutController layoutController;

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    )..emit(EditorReady(document: _docWithText('A')));
    themeCubit = _MockThemeCubit();
    whenListen(
      themeCubit,
      const Stream<ThemeState>.empty(),
      initialState: const ThemeState(AppThemeMode.light),
    );
    layoutController = EditorLayoutController();
  });

  tearDown(() => cubit.close());
  tearDown(() => layoutController.dispose());

  Widget harness() => MaterialApp(
    theme: AppTheme.light,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<EditorCubit>.value(value: cubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: EditorPage(
        projectFuture: Future<Either<Failure, Project>>.value(
          const Left(UnexpectedFailure()),
        ),
        layoutController: layoutController,
      ),
    ),
  );

  void enlarge(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'paleta colapsada mostra a faixa com Widgets e Árvore, e o canvas cresce '
    '(aceite 24)',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();
      final widthBefore = tester.getSize(find.byType(CenterArea)).width;

      layoutController.collapseLeftPanel();
      await tester.pump();

      expect(find.byTooltip('Widgets'), findsOneWidget);
      expect(find.byTooltip('Árvore'), findsOneWidget);
      final widthAfter = tester.getSize(find.byType(CenterArea)).width;
      expect(widthAfter, greaterThan(widthBefore));
    },
  );

  testWidgets(
    'os dois painéis colapsados mostram as duas faixas, sem painel cheio '
    '(aceite 25)',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();

      layoutController
        ..collapseLeftPanel()
        ..collapseRightPanel();
      await tester.pump();

      expect(find.byType(PanelRail), findsNWidgets(2));
      expect(find.byTooltip('Widgets'), findsOneWidget);
      expect(find.byTooltip('Árvore'), findsOneWidget);
      expect(find.byTooltip('Inspector'), findsOneWidget);
      expect(find.text('Página'), findsNothing);
    },
  );

  testWidgets(
    'a faixa esquerda destaca a aba corrente com Semantics(selected:) e '
    'contorno (Fix 3)',
    (tester) async {
      final semantics = tester.ensureSemantics();
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();

      layoutController
        ..setLeftPanelTab(LeftPanelTab.tree)
        ..collapseLeftPanel();
      await tester.pump();

      final treeFinder = find.widgetWithIcon(
        PanelRailButton,
        Icons.account_tree_outlined,
      );
      final widgetsFinder = find.widgetWithIcon(
        PanelRailButton,
        Icons.widgets_outlined,
      );

      expect(
        tester.getSemantics(treeFinder).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(widgetsFinder).flagsCollection.isSelected,
        Tristate.isFalse,
      );

      final treeDecoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: treeFinder,
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      final widgetsDecoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: widgetsFinder,
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;

      expect(treeDecoration.border, isNotNull);
      expect(widgetsDecoration.border, isNull);

      semantics.dispose();
    },
  );

  testWidgets(
    'tocar Árvore na faixa esquerda reabre o painel já na aba Árvore '
    '(aceite 26)',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();
      layoutController.collapseLeftPanel();
      await tester.pump();

      await tester.tap(find.byTooltip('Árvore'));
      await tester.pump();

      expect(layoutController.value.leftPanelCollapsed, isFalse);
      expect(layoutController.value.leftPanelTab, LeftPanelTab.tree);
      expect(find.byType(WidgetTreePanel), findsOneWidget);
    },
  );

  testWidgets(
    'tocar o botão de recolher no cabeçalho do painel esquerdo chama '
    'collapseLeftPanel',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(layoutController.value.leftPanelCollapsed, isFalse);

      await tester.tap(find.byTooltip('Recolher painel'));
      await tester.pump();

      expect(layoutController.value.leftPanelCollapsed, isTrue);
    },
  );

  testWidgets(
    'tocar o botão de recolher no cabeçalho do Inspector chama '
    'collapseRightPanel',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(layoutController.value.rightPanelCollapsed, isFalse);

      await tester.tap(find.byTooltip('Recolher Inspector'));
      await tester.pump();

      expect(layoutController.value.rightPanelCollapsed, isTrue);
    },
  );

  testWidgets(
    'o colapso da paleta (F4b) sobrevive ao colapso do painel em faixa '
    '(aceite 26-A)',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();

      for (final category in ['Básicos', 'Layout', 'Formulário']) {
        await tester.tap(find.byTooltip('Recolher $category'));
        await tester.pump();
      }
      expect(find.byTooltip('Expandir Básicos'), findsOneWidget);
      expect(find.byTooltip('Expandir Layout'), findsOneWidget);
      expect(find.byTooltip('Expandir Formulário'), findsOneWidget);
      expect(find.byTooltip('Recolher Listas'), findsOneWidget);

      layoutController.collapseLeftPanel();
      await tester.pump();
      await tester.tap(find.byTooltip('Widgets'));
      await tester.pump();

      expect(find.byTooltip('Expandir Básicos'), findsOneWidget);
      expect(find.byTooltip('Expandir Layout'), findsOneWidget);
      expect(find.byTooltip('Expandir Formulário'), findsOneWidget);
      expect(find.byTooltip('Recolher Listas'), findsOneWidget);
    },
  );

  group('tela cheia (F7)', () {
    testWidgets(
      'modo ligado esconde a paleta e o Inspector, sem faixa colapsada '
      'sobrando, e o botão de sair fica visível (aceite 32)',
      (tester) async {
        enlarge(tester);
        await tester.pumpWidget(harness());
        await tester.pump();
        layoutController
          ..collapseLeftPanel()
          ..collapseRightPanel();
        await tester.pump();
        expect(find.byType(PanelRail), findsNWidgets(2));

        layoutController.enterFullscreen();
        await tester.pump();

        expect(find.byType(LeftPanel), findsNothing);
        expect(find.byType(InspectorArea), findsNothing);
        expect(find.byType(PanelRail), findsNothing);
        expect(find.byTooltip('Sair da tela cheia (Esc)'), findsOneWidget);
      },
    );

    testWidgets(
      'sair do modo devolve exatamente a mesma largura e o mesmo colapso '
      'renderizados de antes (aceite 33)',
      (tester) async {
        enlarge(tester);
        await tester.pumpWidget(harness());
        await tester.pump();

        // Único caminho real de mudar a largura: arrastar o `ResizeHandle`
        // (como `resizable_split_view_test.dart` já testa), não escrever
        // direto no controller — é o que mantém `_leftWidth` do
        // `ResizableSplitView` e `layoutController.value.leftPanelWidth`
        // sincronizados em produção.
        await tester.drag(
          find.byType(ResizeHandle).first,
          const Offset(60, 0),
        );
        await tester.pump();
        layoutController.collapseRightPanel();
        await tester.pump();

        final widthBefore = tester.getSize(find.byType(LeftPanel)).width;
        expect(find.byType(InspectorArea), findsNothing);
        expect(find.byType(RightPanelRail), findsOneWidget);

        layoutController.enterFullscreen();
        await tester.pump();
        layoutController.exitFullscreen();
        await tester.pump();

        expect(find.byType(LeftPanel), findsOneWidget);
        expect(tester.getSize(find.byType(LeftPanel)).width, widthBefore);
        expect(find.byType(InspectorArea), findsNothing);
        expect(find.byType(RightPanelRail), findsOneWidget);
      },
    );

    testWidgets(
      'com erro de diagnóstico no rodapé, o modo tela cheia não o esconde '
      '(aceite 34/P2)',
      (tester) async {
        cubit.emit(const EditorReady(document: _docWithError));
        enlarge(tester);
        await tester.pumpWidget(harness());
        await tester.pump();
        expect(find.byType(EditorStatusBar), findsOneWidget);

        layoutController.enterFullscreen();
        await tester.pump();

        expect(find.byType(EditorStatusBar), findsOneWidget);
      },
    );

    testWidgets(
      'a visibilidade do rodapé não muda ao entrar em tela cheia — a '
      'F7 não toca a regra de exibição do `StatusBarArea` (P2)',
      (tester) async {
        enlarge(tester);
        await tester.pumpWidget(harness());
        await tester.pump();
        final before = find.byType(EditorStatusBar).evaluate().length;

        layoutController.enterFullscreen();
        await tester.pump();
        final after = find.byType(EditorStatusBar).evaluate().length;

        expect(after, before);
      },
    );
  });

  testWidgets(
    'página recém-montada começa fora do modo de comparação — nem barra da '
    'candidata, nem legenda Rascunho (T5b.20)',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EditorCubit>.value(value: cubit),
              BlocProvider<ThemeCubit>.value(value: themeCubit),
            ],
            child: EditorPage(
              projectFuture: Future<Either<Failure, Project>>.value(
                const Left(UnexpectedFailure()),
              ),
              layoutController: layoutController,
              getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
              getContentVersionUseCase: _MockGetContentVersionUseCase(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VersionCompareCandidateBar), findsNothing);
      expect(find.byType(CanvasCompareDraftLegend), findsNothing);
    },
  );

  group('Histórico — checkpoints chegam ao diálogo (bug 53)', () {
    late _MockGetContentVersionsUseCase getContentVersions;
    late _MockGetContentVersionUseCase getContentVersion;
    late _MockGetContentCheckpointsUseCase getContentCheckpoints;

    setUpAll(loadAppFonts);

    setUp(() {
      getContentVersions = _MockGetContentVersionsUseCase();
      getContentVersion = _MockGetContentVersionUseCase();
      getContentCheckpoints = _MockGetContentCheckpointsUseCase();
    });

    // O botão "Histórico" não vive dentro de `EditorWorkspace`: `AppShellSlot`
    // só publica as ações no `AppShellController`, e é `AppShellTopBar` —
    // montado ao lado, como na produção — quem de fato as desenha. Sem essa
    // faixa aqui, o botão nunca existe na árvore para o teste tocar.
    Future<void> pumpWorkspaceAndOpenHistory(
      WidgetTester tester, {
      required Either<Failure, ContentCheckpointsPage> checkpointsResult,
      Either<Failure, ContentVersionsPage> versionsResult = const Right(
        ContentVersionsPage(items: []),
      ),
    }) async {
      when(
        () => getContentVersions('ct_1'),
      ).thenAnswer((_) async => versionsResult);
      when(
        () => getContentCheckpoints('ct_1'),
      ).thenAnswer((_) async => checkpointsResult);

      final compareModeCubit = VersionCompareModeCubit(
        getContentVersionUseCase: getContentVersion,
        getContentVersionsUseCase: getContentVersions,
        editorCubit: cubit,
      );
      addTearDown(compareModeCubit.close);
      final shellController = AppShellController();
      addTearDown(shellController.dispose);

      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppShellScope(
            controller: shellController,
            child: BlocProvider<EditorCubit>.value(
              value: cubit,
              child: VersionCompareModeScope(
                cubit: compareModeCubit,
                child: Column(
                  children: [
                    const AppShellTopBar(
                      homeRouteName: 'home',
                      themeButton: SizedBox(
                        width: kMinInteractiveDimension,
                        height: kMinInteractiveDimension,
                      ),
                    ),
                    Expanded(
                      child: EditorWorkspace(
                        projectFuture: Future<Either<Failure, Project>>.value(
                          const Left(UnexpectedFailure()),
                        ),
                        layoutController: layoutController,
                        getContentVersionsUseCase: getContentVersions,
                        getContentVersionUseCase: getContentVersion,
                        getContentCheckpointsUseCase: getContentCheckpoints,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Histórico de versões'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'o use case de checkpoints chega ao VersionHistoryCubit — é chamado '
      'ao abrir o diálogo de Histórico',
      (tester) async {
        await pumpWorkspaceAndOpenHistory(
          tester,
          checkpointsResult: const Right(ContentCheckpointsPage(items: [])),
        );

        verify(() => getContentCheckpoints('ct_1')).called(1);
      },
    );

    testWidgets(
      'um checkpoint devolvido pelo dublê é renderizado como CheckpointRow, '
      'com a nota visível',
      (tester) async {
        final checkpoint = ContentCheckpoint(
          id: 'chk_1',
          createdAt: DateTime.utc(2026, 8, 20),
          note: 'Antes do reset de layout',
        );

        await pumpWorkspaceAndOpenHistory(
          tester,
          checkpointsResult: Right(
            ContentCheckpointsPage(items: [checkpoint]),
          ),
        );

        expect(find.byType(CheckpointRow), findsOneWidget);
        expect(find.text('Antes do reset de layout'), findsOneWidget);
      },
    );

    testWidgets(
      'sem nenhuma versão publicada mas com um checkpoint, o diálogo mostra '
      'o ponto salvo e não a mensagem de vazio',
      (tester) async {
        final checkpoint = ContentCheckpoint(
          id: 'chk_2',
          createdAt: DateTime.utc(2026, 8, 19),
          note: 'Rascunho salvo antes do almoço',
        );

        await pumpWorkspaceAndOpenHistory(
          tester,
          checkpointsResult: Right(
            ContentCheckpointsPage(items: [checkpoint]),
          ),
        );

        expect(find.byType(CheckpointRow), findsOneWidget);
        expect(
          find.text('Nenhuma versão ou ponto salvo ainda.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'sem versões e sem checkpoints, o diálogo continua mostrando a '
      'mensagem de vazio',
      (tester) async {
        await pumpWorkspaceAndOpenHistory(
          tester,
          checkpointsResult: const Right(ContentCheckpointsPage(items: [])),
        );

        expect(find.byType(CheckpointRow), findsNothing);
        expect(
          find.text('Nenhuma versão ou ponto salvo ainda.'),
          findsOneWidget,
        );
      },
    );
  });
}
