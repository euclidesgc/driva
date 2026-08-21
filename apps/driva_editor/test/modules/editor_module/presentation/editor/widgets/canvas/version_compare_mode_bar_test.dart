import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
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
    properties: {'text': 'como era na v10'},
  ),
);

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
              version: 10,
              spec: _candidateSpec,
              createdAt: DateTime.utc(2026, 8, 16),
            ),
            baseSpec: _draftSpec,
            result: compareContentSpecs(_draftSpec, _candidateSpec),
            versions: const [],
          ),
        );
  });

  tearDown(() async {
    await compareCubit.close();
    await editorCubit.close();
  });

  Future<void> pumpBar(WidgetTester tester, {double width = 1200}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: VersionCompareModeBar(
              cubit: compareCubit,
              editorCubit: editorCubit,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'identifica o rascunho e a candidata ao mesmo tempo, cada um no seu '
    'lado da barra',
    (tester) async {
      await pumpBar(tester);

      expect(find.byType(CanvasCompareDraftLegend), findsOneWidget);
      expect(find.text('Versão 10'), findsOneWidget);

      final draftLeft = tester.getRect(find.byType(VersionCompareDraftLabel));
      final candidateLeft = tester.getRect(
        find.byType(VersionCompareCandidateBar),
      );
      expect(
        draftLeft.right,
        lessThanOrEqualTo(candidateLeft.left),
        reason:
            'o rótulo do rascunho fica alinhado à metade esquerda, o da '
            'candidata à direita',
      );
    },
  );

  testWidgets(
    'navegação entre versões, carregar versão inteira e fechar continuam '
    'presentes e acionáveis',
    (tester) async {
      await pumpBar(tester);

      expect(find.byTooltip('Versão mais nova'), findsOneWidget);
      expect(find.byTooltip('Versão mais antiga'), findsOneWidget);
      expect(
        find.byTooltip('Carregar versão inteira no rascunho'),
        findsOneWidget,
      );
      expect(find.byTooltip('Fechar comparação'), findsOneWidget);

      await tester.tap(find.byTooltip('Fechar comparação'));
      await tester.pumpAndSettle();

      final state = compareCubit.state;
      expect(state, isA<VersionCompareModeInactive>());
    },
  );

  testWidgets('some quando o modo de comparação não está ativo', (
    tester,
  ) async {
    compareCubit.emit(const VersionCompareModeInactive());
    await pumpBar(tester);

    expect(find.byType(CanvasCompareDraftLegend), findsNothing);
    expect(find.byType(VersionCompareCandidateBar), findsNothing);
  });
}
