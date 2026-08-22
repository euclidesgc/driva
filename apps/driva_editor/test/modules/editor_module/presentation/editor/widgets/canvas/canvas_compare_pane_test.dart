import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_pane.dart';
import 'package:flutter/material.dart';
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

const _draftSpec = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'n_root',
    type: 'text',
    properties: {'text': 'rascunho ao vivo'},
  ),
);

const _candidateSpec = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'n_root',
    type: 'text',
    properties: {'text': 'como era na v3'},
  ),
);

const _loadFullVersionLabel = 'Carregar versão inteira no rascunho';

void main() {
  late EditorCubit editorCubit;
  late VersionCompareModeCubit compareCubit;

  setUp(() {
    editorCubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    )..emit(const EditorReady(document: _draftSpec));

    compareCubit =
        VersionCompareModeCubit(
          getContentVersionUseCase: _MockGetContentVersionUseCase(),
          getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
          editorCubit: editorCubit,
        )..emit(
          VersionCompareModeActive(
            candidate: LoadedContentVersion(
              version: 3,
              spec: _candidateSpec,
              createdAt: DateTime.utc(2026, 8, 16),
            ),
            baseSpec: _draftSpec,
            result: compareContentSpecs(_draftSpec, _candidateSpec),
          ),
        );
  });

  tearDown(() async {
    await compareCubit.close();
    await editorCubit.close();
  });

  Future<void> pumpPane(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CanvasComparePane(
            device: DevicePreset.smartphone,
            effectiveScale: 0.8,
            cubit: compareCubit,
            editorCubit: editorCubit,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a seta da barra da candidata carrega a versão inteira no rascunho, '
    'passando pela confirmação existente',
    (tester) async {
      await pumpPane(tester);

      expect(find.byTooltip(_loadFullVersionLabel), findsOneWidget);

      await tester.tap(find.byTooltip(_loadFullVersionLabel));
      await tester.pumpAndSettle();

      expect(find.text('Carregar a versão 3 no rascunho?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      final state = editorCubit.state as EditorReady;
      expect(state.document, _candidateSpec);
      expect(state.saveStatus, SaveStatus.dirty);
    },
  );

  testWidgets('cancelar a confirmação não muda o documento do editor', (
    tester,
  ) async {
    await pumpPane(tester);

    await tester.tap(find.byTooltip(_loadFullVersionLabel));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    final state = editorCubit.state as EditorReady;
    expect(state.document, _draftSpec);
  });
}
