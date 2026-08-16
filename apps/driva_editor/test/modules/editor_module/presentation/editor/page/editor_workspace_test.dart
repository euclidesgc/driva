import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/editor_page.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/center_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

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

void main() {
  late EditorCubit cubit;
  late _MockThemeCubit themeCubit;
  late EditorLayoutController layoutController;

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
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
}
