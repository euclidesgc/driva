import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class _MockPublishContentUseCase extends Mock
    implements PublishContentUseCase {}

class _MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class _MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

class _MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class _MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

void main() {
  late EditorCubit cubit;

  const document = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
  );

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    )..emit(const EditorReady(document: document));
  });

  tearDown(() => cubit.close());

  Widget harness({VersionCompareModeCubit? compareCubit}) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: BlocProvider<EditorCubit>.value(
        value: cubit,
        child: SizedBox(
          width: 280,
          height: 600,
          child: compareCubit == null
              ? const LeftPanel()
              : VersionCompareModeScope(
                  cubit: compareCubit,
                  child: const LeftPanel(),
                ),
        ),
      ),
    ),
  );

  group('sem EditorLayoutScope acima (Fix T3)', () {
    testWidgets('monta sem crashar', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(LeftPanel), findsOneWidget);
    });

    testWidgets('o botão de recolher não aparece', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.byTooltip('Recolher painel'), findsNothing);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('as abas Widgets e Árvore continuam funcionais', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.text('Widgets'), findsOneWidget);
      expect(find.text('Árvore'), findsOneWidget);

      await tester.tap(find.text('Árvore'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('marcadores de diff do modo de comparação (T5b.8)', () {
    const rootedDocument = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: SduiNode(id: 'n_root', type: 'text', properties: {'data': 'Olá'}),
    );

    VersionCompareModeActive activeAgainst(
      ContentSpec candidateSpec,
      int version,
    ) {
      return VersionCompareModeActive(
        candidate: LoadedContentVersion(
          version: version,
          spec: candidateSpec,
          createdAt: DateTime.utc(2026, 8, 16),
        ),
        baseSpec: rootedDocument,
        result: compareContentSpecs(rootedDocument, candidateSpec),
      );
    }

    VersionCompareModeCubit buildCompareCubit() => VersionCompareModeCubit(
      getContentVersionUseCase: _MockGetContentVersionUseCase(),
      getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
      editorCubit: cubit,
    );

    Future<void> openTree(WidgetTester tester) async {
      await tester.tap(find.text('Árvore'));
      await tester.pumpAndSettle();
    }

    testWidgets('trocar a candidata troca o marcador da mesma linha', (
      tester,
    ) async {
      cubit.emit(const EditorReady(document: rootedDocument));
      final compareCubit = buildCompareCubit();
      addTearDown(compareCubit.close);

      const propsChangedSpec = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_1',
        name: 'Home',
        slug: 'home',
        root: SduiNode(
          id: 'n_root',
          type: 'text',
          properties: {'data': 'Outro texto'},
        ),
      );
      const typeChangedSpec = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_1',
        name: 'Home',
        slug: 'home',
        root: SduiNode(id: 'n_root', type: 'button'),
      );

      compareCubit.emit(activeAgainst(propsChangedSpec, 3));
      await tester.pumpWidget(harness(compareCubit: compareCubit));
      await openTree(tester);

      final rowFinder = find.ancestor(
        of: find.textContaining('Olá'),
        matching: find.byType(TreeRowContent),
      );
      TreeRowDiffMarker markerInRow() => tester.widget<TreeRowDiffMarker>(
        find.descendant(
          of: rowFinder,
          matching: find.byType(TreeRowDiffMarker),
        ),
      );

      expect(
        markerInRow().kind,
        VersionCompareMarkerKind.propertiesChanged,
      );

      compareCubit.emit(activeAgainst(typeChangedSpec, 2));
      await tester.pumpAndSettle();

      expect(markerInRow().kind, VersionCompareMarkerKind.typeChanged);
    });

    testWidgets('modo inativo: nenhuma linha da árvore tem marcador', (
      tester,
    ) async {
      cubit.emit(const EditorReady(document: rootedDocument));
      final compareCubit = buildCompareCubit();
      addTearDown(compareCubit.close);

      await tester.pumpWidget(harness(compareCubit: compareCubit));
      await openTree(tester);

      expect(find.byType(TreeRowDiffMarker), findsNothing);
    });
  });
}
