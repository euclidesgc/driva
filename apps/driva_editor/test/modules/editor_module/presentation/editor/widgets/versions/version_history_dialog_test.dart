import 'dart:async';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_history_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_version_into_draft_confirm_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_history_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class MockPublishContentUseCase extends Mock implements PublishContentUseCase {}

class MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

class MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

void main() {
  late MockLoadContentUseCase loadContent;
  late MockSaveDraftUseCase saveDraft;
  late MockPublishContentUseCase publishContent;
  late MockUnpublishContentUseCase unpublishContent;
  late MockRestoreContentVersionUseCase restoreContentVersion;
  late MockGetContentVersionsUseCase getContentVersions;
  late MockGetContentVersionUseCase getContentVersion;

  const document = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(id: 'nd_root', type: 'text', properties: {'data': 'Oi'}),
  );

  const historicalSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'text',
      properties: {'data': 'versão antiga'},
    ),
  );

  final loadedVersion = LoadedContentVersion(
    version: 3,
    spec: historicalSpec,
    createdAt: DateTime.utc(2026, 8, 16),
    note: 'Ajuste no banner',
  );

  final page = ContentVersionsPage(
    items: [ContentVersion(version: 3, createdAt: DateTime.utc(2026, 8, 16))],
  );

  setUp(() {
    loadContent = MockLoadContentUseCase();
    saveDraft = MockSaveDraftUseCase();
    publishContent = MockPublishContentUseCase();
    unpublishContent = MockUnpublishContentUseCase();
    restoreContentVersion = MockRestoreContentVersionUseCase();
    getContentVersions = MockGetContentVersionsUseCase();
    getContentVersion = MockGetContentVersionUseCase();

    when(
      () => getContentVersions('ct_1'),
    ).thenAnswer((_) async => Right(page));
  });

  EditorCubit buildEditorCubit({bool dirty = false}) =>
      EditorCubit(
        loadContentUseCase: loadContent,
        saveDraftUseCase: saveDraft,
        publishContentUseCase: publishContent,
        unpublishContentUseCase: unpublishContent,
        restoreContentVersionUseCase: restoreContentVersion,
        projectId: 'p1',
      )..emit(
        EditorReady(
          document: document,
          saveStatus: dirty ? SaveStatus.dirty : SaveStatus.saved,
        ),
      );

  VersionCompareModeCubit buildCompareMode(EditorCubit editorCubit) =>
      VersionCompareModeCubit(
        getContentVersionUseCase: getContentVersion,
        getContentVersionsUseCase: getContentVersions,
        editorCubit: editorCubit,
      );

  Future<void> openHistory(
    WidgetTester tester,
    EditorCubit editorCubit, {
    VersionCompareModeCubit? compareMode,
  }) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyCubit = VersionHistoryCubit(
      getContentVersionsUseCase: getContentVersions,
      contentId: 'ct_1',
    );
    unawaited(historyCubit.load());
    addTearDown(historyCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: historyCubit,
                  child: VersionHistoryDialog(
                    editorCubit: editorCubit,
                    compareModeCubit:
                        compareMode ?? buildCompareMode(editorCubit),
                    getContentVersionUseCase: getContentVersion,
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  group('Comparar', () {
    testWidgets(
      'liga o modo de comparação com a versão da linha e fecha o histórico — '
      'a comparação passa a acontecer no canvas, não noutro diálogo',
      (tester) async {
        final editorCubit = buildEditorCubit();
        addTearDown(editorCubit.close);
        final compareMode = buildCompareMode(editorCubit);
        addTearDown(compareMode.close);
        when(
          () => getContentVersion('ct_1', 3),
        ).thenAnswer((_) async => Right(loadedVersion));

        await openHistory(tester, editorCubit, compareMode: compareMode);
        await tester.tap(find.text('Comparar'));
        await tester.pumpAndSettle();

        expect(find.byType(VersionHistoryDialog), findsNothing);
        expect(
          compareMode.state,
          isA<VersionCompareModeActive>().having(
            (s) => s.candidate.version,
            'candidate.version',
            3,
          ),
        );
      },
    );

    testWidgets(
      'com o modo já ativo, comparar outra linha troca a candidata sem passar '
      'por inativo',
      (tester) async {
        final editorCubit = buildEditorCubit();
        addTearDown(editorCubit.close);
        final compareMode = buildCompareMode(editorCubit);
        addTearDown(compareMode.close);

        final olderVersion = LoadedContentVersion(
          version: 2,
          spec: historicalSpec,
          createdAt: DateTime.utc(2026, 8, 15),
        );
        when(
          () => getContentVersion('ct_1', 3),
        ).thenAnswer((_) async => Right(loadedVersion));
        when(
          () => getContentVersion('ct_1', 2),
        ).thenAnswer((_) async => Right(olderVersion));
        when(() => getContentVersions('ct_1')).thenAnswer(
          (_) async => Right(
            ContentVersionsPage(
              items: [
                ContentVersion(
                  version: 3,
                  createdAt: DateTime.utc(2026, 8, 16),
                ),
                ContentVersion(
                  version: 2,
                  createdAt: DateTime.utc(2026, 8, 15),
                ),
              ],
            ),
          ),
        );

        await compareMode.enter(3);
        final seen = <VersionCompareModeState>[];
        final subscription = compareMode.stream.listen(seen.add);
        addTearDown(subscription.cancel);

        await openHistory(tester, editorCubit, compareMode: compareMode);
        await tester.tap(find.text('Comparar').last);
        await tester.pumpAndSettle();

        expect(find.byType(VersionHistoryDialog), findsNothing);
        expect(
          compareMode.state,
          isA<VersionCompareModeActive>().having(
            (s) => s.candidate.version,
            'candidate.version',
            2,
          ),
        );
        expect(
          seen.whereType<VersionCompareModeInactive>(),
          isEmpty,
          reason: 'trocar de versão não pode piscar o modo desligado',
        );
      },
    );
  });

  group('Ver', () {
    testWidgets(
      'não dispara PUT/POST nenhum: nenhum use case de escrita é chamado',
      (tester) async {
        when(
          () => getContentVersion('ct_1', 3),
        ).thenAnswer((_) async => Right(loadedVersion));
        final editorCubit = buildEditorCubit();
        addTearDown(editorCubit.close);

        await openHistory(tester, editorCubit);
        await tester.tap(find.widgetWithText(FilledButton, 'Ver'));
        await tester.pumpAndSettle();

        expect(find.text('Somente leitura'), findsOneWidget);
        verifyZeroInteractions(saveDraft);
        verifyZeroInteractions(publishContent);
        verifyZeroInteractions(unpublishContent);
        verifyZeroInteractions(restoreContentVersion);
      },
    );

    testWidgets(
      'não deixa o editor sujo, não mexe no undo nem no ponteiro publicado',
      (tester) async {
        when(
          () => getContentVersion('ct_1', 3),
        ).thenAnswer((_) async => Right(loadedVersion));
        final editorCubit = buildEditorCubit();
        addTearDown(editorCubit.close);
        final before = editorCubit.state;

        await openHistory(tester, editorCubit);
        await tester.tap(find.widgetWithText(FilledButton, 'Ver'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Fechar').last);
        await tester.pumpAndSettle();

        expect(editorCubit.state, before);
      },
    );

    testWidgets('falha ao ler a versão mantém o histórico aberto e mostra '
        'o erro', (tester) async {
      when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      final editorCubit = buildEditorCubit();
      addTearDown(editorCubit.close);

      await openHistory(tester, editorCubit);
      await tester.tap(find.widgetWithText(FilledButton, 'Ver'));
      await tester.pumpAndSettle();

      expect(
        find.text('Sem conexão com o servidor. Tente de novo.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Fechar').last);
      await tester.pumpAndSettle();

      expect(find.text('Histórico de versões'), findsOneWidget);
    });
  });

  group('Carregar no rascunho', () {
    testWidgets(
      'não chama o endpoint restore, deixa o editor sujo e some com o '
      'histórico',
      (tester) async {
        when(
          () => getContentVersion('ct_1', 3),
        ).thenAnswer((_) async => Right(loadedVersion));
        final editorCubit = buildEditorCubit();
        addTearDown(editorCubit.close);

        await openHistory(tester, editorCubit);
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Carregar no rascunho'),
        );
        await tester.pumpAndSettle();

        final state = editorCubit.state as EditorReady;
        expect(state.document, historicalSpec);
        expect(state.saveStatus, SaveStatus.dirty);
        expect(state.canUndo, isTrue);
        verifyZeroInteractions(restoreContentVersion);
        verifyZeroInteractions(saveDraft);
        verifyZeroInteractions(publishContent);
        expect(find.text('Histórico de versões'), findsNothing);
      },
    );

    testWidgets('rascunho sujo: a confirmação só permite descartar ou '
        'cancelar', (tester) async {
      when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => Right(loadedVersion));
      final editorCubit = buildEditorCubit(dirty: true);
      addTearDown(editorCubit.close);

      await openHistory(tester, editorCubit);
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          FilledButton,
          'Descartar alterações locais e carregar',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect((editorCubit.state as EditorReady).document, document);
      expect(find.text('Histórico de versões'), findsOneWidget);
    });

    testWidgets('falha ao ler a versão mostra erro e não abre confirmação '
        'nenhuma', (tester) async {
      when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      final editorCubit = buildEditorCubit();
      addTearDown(editorCubit.close);
      final before = editorCubit.state;

      await openHistory(tester, editorCubit);
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Sem conexão com o servidor. Tente de novo.'),
        findsOneWidget,
      );
      expect(
        find.byType(LoadVersionIntoDraftConfirmDialog),
        findsNothing,
      );
      expect(editorCubit.state, before);
      expect(find.text('Histórico de versões'), findsOneWidget);
    });
  });
}
