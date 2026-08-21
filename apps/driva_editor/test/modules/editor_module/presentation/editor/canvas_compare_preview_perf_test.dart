import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/canvas_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/preview_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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
  late EditorCubit editorCubit;
  late VersionCompareModeCubit compareCubit;
  late EditorLayoutController layoutController;
  late _MockGetContentVersionUseCase getVersion;
  late _MockGetContentVersionsUseCase getVersions;

  final candidateV2 = LoadedContentVersion(
    version: 2,
    spec: _docWithText('candidata v2'),
    createdAt: DateTime.utc(2026, 8),
  );
  final candidateV1 = LoadedContentVersion(
    version: 1,
    spec: _docWithText('candidata v1'),
    createdAt: DateTime.utc(2026, 7),
  );

  setUp(() {
    editorCubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    )..emit(EditorReady(document: _docWithText('A')));

    getVersion = _MockGetContentVersionUseCase();
    getVersions = _MockGetContentVersionsUseCase();
    when(
      () => getVersion('ct_1', 2),
    ).thenAnswer((_) async => Right(candidateV2));
    when(
      () => getVersion('ct_1', 1),
    ).thenAnswer((_) async => Right(candidateV1));
    when(() => getVersions('ct_1', cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => Right(
        ContentVersionsPage(
          items: [
            ContentVersion(version: 2, createdAt: DateTime.utc(2026, 8)),
            ContentVersion(version: 1, createdAt: DateTime.utc(2026, 7)),
          ],
        ),
      ),
    );

    compareCubit = VersionCompareModeCubit(
      getContentVersionUseCase: getVersion,
      getContentVersionsUseCase: getVersions,
      editorCubit: editorCubit,
    );

    layoutController = EditorLayoutController();
  });

  tearDown(() async {
    await editorCubit.close();
    await compareCubit.close();
    layoutController.dispose();
  });

  void enlarge(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget harness() => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: BlocProvider<EditorCubit>.value(
        value: editorCubit,
        child: EditorLayoutScope(
          controller: layoutController,
          child: VersionCompareModeScope(
            cubit: compareCubit,
            child: const CanvasArea(),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'modo comparação: trocar de candidata não rebuilda o mock do rascunho',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();
      await compareCubit.enter(2);
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      var builds = 0;
      final previous = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element.widget is PreviewSurface) builds++;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previous);

      await compareCubit.selectVersion(1);
      await tester.pumpAndSettle();

      expect(builds, 0);
    },
  );

  testWidgets(
    'modo comparação: 5 teclas num campo de propriedade rebuildam o mock do '
    'rascunho no máximo 1 vez — mesmo teto de fora do modo comparação',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();
      await compareCubit.enter(2);
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      var builds = 0;
      final previous = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element.widget is PreviewSurface) builds++;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previous);

      for (final letter in ['B', 'BC', 'BCD', 'BCDE', 'BCDEF']) {
        await tester.runAsync(() async {
          editorCubit.updateProps('nd_text', {'data': letter});
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pump();
      }

      expect(builds, lessThanOrEqualTo(1));
    },
  );
}
