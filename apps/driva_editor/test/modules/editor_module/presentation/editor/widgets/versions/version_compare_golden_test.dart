import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_copy_arrow_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_exclusive_node_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../support/golden.dart';

class MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class MockPublishContentUseCase extends Mock implements PublishContentUseCase {}

class MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  late MockLoadContentUseCase loadContent;
  late MockSaveDraftUseCase saveDraft;
  late MockPublishContentUseCase publishContent;
  late MockUnpublishContentUseCase unpublishContent;
  late MockRestoreContentVersionUseCase restoreContentVersion;
  late MockGetContentVersionUseCase getContentVersion;

  const draftSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    safeArea: {'top': true},
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(
          id: 'nd_props',
          type: 'text',
          properties: {'data': 'rascunho'},
        ),
        SduiNode(
          id: 'nd_events',
          type: 'text',
          properties: {'data': 'x'},
          events: {
            'onTap': {'action': 'noop'},
          },
        ),
        SduiNode(id: 'nd_type', type: 'text'),
        SduiNode(id: 'nd_onlybase', type: 'text'),
      ],
    ),
  );

  const candidateSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home v2',
    slug: 'home',
    safeArea: {'top': false},
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(
          id: 'nd_props',
          type: 'text',
          properties: {'data': 'candidata'},
        ),
        SduiNode(
          id: 'nd_events',
          type: 'text',
          properties: {'data': 'x'},
          events: {
            'onTap': {'action': 'go'},
          },
        ),
        SduiNode(id: 'nd_type', type: 'container'),
        SduiNode(id: 'nd_onlycandidate', type: 'text'),
      ],
    ),
  );

  final candidate = LoadedContentVersion(
    version: 7,
    spec: candidateSpec,
    createdAt: DateTime.utc(2026, 8, 16),
  );

  setUp(() {
    loadContent = MockLoadContentUseCase();
    saveDraft = MockSaveDraftUseCase();
    publishContent = MockPublishContentUseCase();
    unpublishContent = MockUnpublishContentUseCase();
    restoreContentVersion = MockRestoreContentVersionUseCase();
    getContentVersion = MockGetContentVersionUseCase();
    when(
      () => getContentVersion('ct_1', 7),
    ).thenAnswer((_) async => Right(candidate));
  });

  EditorCubit buildEditorCubit() => EditorCubit(
    loadContentUseCase: loadContent,
    saveDraftUseCase: saveDraft,
    publishContentUseCase: publishContent,
    unpublishContentUseCase: unpublishContent,
    restoreContentVersionUseCase: restoreContentVersion,
    projectId: 'p1',
  )..emit(const EditorReady(document: draftSpec));

  Future<void> pumpDialog(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final editorCubit = buildEditorCubit();
    addTearDown(editorCubit.close);
    final compareCubit = VersionCompareCubit(
      getContentVersionUseCase: getContentVersion,
      editorCubit: editorCubit,
      contentId: 'ct_1',
      candidateVersion: 7,
    );
    addTearDown(compareCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: compareCubit,
          child: const VersionCompareDialog(),
        ),
      ),
    );
    await compareCubit.load();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'golden: comparação desktop — marcadores e os dois previews lado a '
    'lado',
    (tester) async {
      await pumpDialog(tester, const Size(1400, 1200));

      await expectLater(
        find.byType(VersionCompareDialog),
        matchesGoldenFile('goldens/version_compare_desktop.png'),
      );
    },
  );

  testWidgets(
    'golden: comparação desktop — nós em comum alterados, com a seta de '
    'cópia',
    (tester) async {
      await pumpDialog(tester, const Size(1400, 1200));
      await tester.ensureVisible(find.byType(VersionCompareCopyArrowButton));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(VersionCompareDialog),
        matchesGoldenFile('goldens/version_compare_desktop_changed_nodes.png'),
      );
    },
  );

  testWidgets(
    'golden: comparação compacta — controle segmentado, sem colunas '
    'espremidas',
    (tester) async {
      await pumpDialog(tester, const Size(700, 1200));

      await expectLater(
        find.byType(VersionCompareDialog),
        matchesGoldenFile('goldens/version_compare_compact.png'),
      );
    },
  );

  testWidgets(
    'golden: rótulo do nó exclusivo — a caixa acompanha o texto, nunca '
    'corta com reticências',
    (tester) async {
      tester.view.physicalSize = const Size(320, 60);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const Scaffold(
            body: VersionCompareExclusiveNodeTile(
              nodeId: 'nd_onlycandidate',
              nodeType: 'text',
              kind: VersionCompareMarkerKind.onlyInCandidate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await withStricterGolden(0.01, () async {
        await expectLater(
          find.byType(VersionCompareExclusiveNodeTile),
          matchesGoldenFile(
            'goldens/version_compare_exclusive_node_tile.png',
          ),
        );
      });
    },
  );
}
