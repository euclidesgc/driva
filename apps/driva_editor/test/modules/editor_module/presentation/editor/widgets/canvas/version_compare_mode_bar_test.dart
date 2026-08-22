import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
import 'package:flutter/material.dart';
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

const _candidateSpecV10 = ContentSpec(
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

const _candidateSpecV9 = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'n_root',
    type: 'text',
    properties: {'text': 'como era na v9'},
  ),
);

const _olderTooltip = 'Item mais antigo do histórico';
const _newerTooltip = 'Item mais novo do histórico';

void main() {
  late EditorCubit editorCubit;
  late VersionCompareModeCubit compareCubit;
  late _MockGetContentVersionUseCase getVersion;

  final versionV10 = LoadedContentVersion(
    version: 10,
    spec: _candidateSpecV10,
    createdAt: DateTime.utc(2026, 8, 16),
  );
  final versionV9 = LoadedContentVersion(
    version: 9,
    spec: _candidateSpecV9,
    createdAt: DateTime.utc(2026, 8, 10),
  );

  VersionCompareModeActive activeAt(
    LoadedContentVersion candidate, {
    List<ContentVersion> versions = const [],
  }) => VersionCompareModeActive(
    candidate: candidate,
    baseSpec: _draftSpec,
    result: compareContentSpecs(_draftSpec, candidate.spec),
    versions: versions,
  );

  setUp(() {
    editorCubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    )..emit(const EditorReady(document: _draftSpec));

    getVersion = _MockGetContentVersionUseCase();
    when(
      () => getVersion('ct_1', 9),
    ).thenAnswer((_) async => Right(versionV9));
    when(
      () => getVersion('ct_1', 10),
    ).thenAnswer((_) async => Right(versionV10));

    compareCubit = VersionCompareModeCubit(
      getContentVersionUseCase: getVersion,
      getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
      editorCubit: editorCubit,
    )..emit(activeAt(versionV10));
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
    'a seta de carregar versão inteira abre a confirmação com o número '
    'certo',
    (tester) async {
      await pumpBar(tester);

      await tester.tap(find.byTooltip('Carregar versão inteira no rascunho'));
      await tester.pumpAndSettle();

      expect(find.text('Carregar a versão 10 no rascunho?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      final state = editorCubit.state as EditorReady;
      expect(state.document, _candidateSpecV10);
    },
  );

  testWidgets(
    '“Item mais antigo” desce um índice na lista paginada e troca a '
    'candidata de verdade',
    (tester) async {
      compareCubit.emit(
        activeAt(
          versionV10,
          versions: [
            ContentVersion(version: 10, createdAt: versionV10.createdAt),
            ContentVersion(version: 9, createdAt: versionV9.createdAt),
          ],
        ),
      );
      await pumpBar(tester);

      await tester.tap(find.byTooltip(_olderTooltip));
      await tester.pumpAndSettle();

      final state = compareCubit.state as VersionCompareModeActive;
      expect(state.candidate, versionV9);
      expect(find.text('Versão 9'), findsOneWidget);
    },
  );

  testWidgets(
    '“Item mais novo” sobe um índice na lista paginada e troca a '
    'candidata de verdade',
    (tester) async {
      compareCubit.emit(
        activeAt(
          versionV9,
          versions: [
            ContentVersion(version: 10, createdAt: versionV10.createdAt),
            ContentVersion(version: 9, createdAt: versionV9.createdAt),
          ],
        ),
      );
      await pumpBar(tester);

      await tester.tap(find.byTooltip(_newerTooltip));
      await tester.pumpAndSettle();

      final state = compareCubit.state as VersionCompareModeActive;
      expect(state.candidate, versionV10);
      expect(find.text('Versão 10'), findsOneWidget);
    },
  );

  testWidgets(
    'candidata fora da linha do tempo já carregada: ‹ › ficam desabilitados '
    'em vez de virarem botão morto',
    (tester) async {
      await pumpBar(tester);

      final older = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      final newer = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(older.onPressed, isNull);
      expect(newer.onPressed, isNull);
    },
  );

  testWidgets('Fechar comparação sai do modo', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.byTooltip('Fechar comparação'));
    await tester.pumpAndSettle();

    expect(compareCubit.state, isA<VersionCompareModeInactive>());
  });

  testWidgets(
    'nas pontas do histórico as setas continuam habilitadas — '
    '`stepOlder`/`stepNewer` não têm para onde ir e não emitem, em vez de '
    'a barra desabilitar o botão',
    (tester) async {
      compareCubit.emit(
        activeAt(
          versionV10,
          versions: [
            ContentVersion(version: 10, createdAt: versionV10.createdAt),
          ],
        ),
      );
      await pumpBar(tester);

      final older = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      final newer = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(older.onPressed, isNotNull);
      expect(newer.onPressed, isNotNull);

      await tester.tap(find.byTooltip(_olderTooltip));
      await tester.tap(find.byTooltip(_newerTooltip));
      await tester.pumpAndSettle();

      final state = compareCubit.state as VersionCompareModeActive;
      expect(state.candidate, versionV10);
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
