import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_copy_arrow_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_fullscreen_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_windowed_shell.dart';
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

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

void main() {
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

  const duplicateSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(id: 'dup', type: 'text'),
        SduiNode(id: 'dup', type: 'text'),
      ],
    ),
  );

  final candidate = LoadedContentVersion(
    version: 5,
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
  });

  EditorCubit buildEditorCubit(ContentSpec document) => EditorCubit(
    loadContentUseCase: loadContent,
    saveDraftUseCase: saveDraft,
    publishContentUseCase: publishContent,
    unpublishContentUseCase: unpublishContent,
    restoreContentVersionUseCase: restoreContentVersion,
    projectId: 'p1',
  )..emit(EditorReady(document: document));

  Future<VersionCompareCubit> pumpDialog(
    WidgetTester tester,
    EditorCubit editorCubit, {
    Size size = const Size(1400, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final compareCubit = VersionCompareCubit(
      getContentVersionUseCase: getContentVersion,
      editorCubit: editorCubit,
      contentId: 'ct_1',
      candidateVersion: 5,
    );
    addTearDown(compareCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: compareCubit,
          child: const VersionCompareDialog(),
        ),
      ),
    );
    await compareCubit.load();
    await tester.pumpAndSettle();
    return compareCubit;
  }

  testWidgets(
    'marcadores aparecem com ícone e texto para cada diferença real, sem '
    'sumir por omissão',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);

      expect(find.text('Propriedades alteradas'), findsOneWidget);
      expect(find.text('Eventos alterados'), findsOneWidget);
      expect(find.text('Tipo mudou'), findsOneWidget);
      expect(find.text('Somente no rascunho'), findsOneWidget);
      expect(find.text('Somente na versão'), findsOneWidget);
      expect(find.text('Safe area alterada'), findsOneWidget);
      expect(find.text('Metadados alterados'), findsOneWidget);
    },
  );

  testWidgets(
    'a seta só existe no nó com mesmo ID e mesmo tipo nos dois lados',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);

      expect(find.byType(VersionCompareCopyArrowButton), findsOneWidget);
    },
  );

  testWidgets(
    'copiar traz só as propriedades, e Ctrl+Z desfaz — sem tocar em '
    'eventos, safe area ou metadados',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);
      await tester.ensureVisible(find.byType(VersionCompareCopyArrowButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(VersionCompareCopyArrowButton));
      await tester.pumpAndSettle();

      final afterCopy = editorCubit.state as EditorReady;
      expect(
        findNode(afterCopy.document.root!, 'nd_props')!.properties,
        {'data': 'candidata'},
      );
      expect(afterCopy.document.safeArea, {'top': true});
      expect(afterCopy.document.name, 'Home');
      expect(
        findNode(afterCopy.document.root!, 'nd_events')!.events,
        {
          'onTap': {'action': 'noop'},
        },
      );
      expect(afterCopy.saveStatus, SaveStatus.dirty);

      editorCubit.undo();
      final afterUndo = editorCubit.state as EditorReady;
      expect(afterUndo.document, draftSpec);
    },
  );

  testWidgets('abrir a comparação não dispara save/publish/unpublish/restore '
      'e não altera o documento', (tester) async {
    when(
      () => getContentVersion('ct_1', 5),
    ).thenAnswer((_) async => Right(candidate));
    final editorCubit = buildEditorCubit(draftSpec);
    addTearDown(editorCubit.close);
    final before = editorCubit.state;

    await pumpDialog(tester, editorCubit);

    expect(editorCubit.state, before);
    verifyZeroInteractions(saveDraft);
    verifyZeroInteractions(publishContent);
    verifyZeroInteractions(unpublishContent);
    verifyZeroInteractions(restoreContentVersion);
  });

  testWidgets(
    'ID duplicado: bloqueia a comparação inteira, sem seta e sem mutar o '
    'rascunho',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(duplicateSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);

      expect(
        find.textContaining('não pode ser comparada com segurança'),
        findsOneWidget,
      );
      expect(find.byType(VersionCompareCopyArrowButton), findsNothing);
      expect((editorCubit.state as EditorReady).document, duplicateSpec);
    },
  );

  testWidgets(
    'estrutura/tipo: explica a ausência da seta e oferece carregar a '
    'versão inteira',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);

      expect(
        find.widgetWithText(
          OutlinedButton,
          'Carregar versão inteira no rascunho',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(
          OutlinedButton,
          'Carregar versão inteira no rascunho',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Carregar no rascunho'),
      );
      await tester.pumpAndSettle();

      final state = editorCubit.state as EditorReady;
      expect(state.document, candidateSpec);
      verifyZeroInteractions(restoreContentVersion);
    },
  );

  testWidgets('desktop: usa a moldura larga com duas colunas de nós '
      'exclusivos', (tester) async {
    when(
      () => getContentVersion('ct_1', 5),
    ).thenAnswer((_) async => Right(candidate));
    final editorCubit = buildEditorCubit(draftSpec);
    addTearDown(editorCubit.close);

    await pumpDialog(tester, editorCubit);

    expect(find.byType(VersionCompareWindowedShell), findsOneWidget);
    expect(find.byType(VersionCompareFullscreenShell), findsNothing);
  });

  testWidgets(
    'compacto: usa controle segmentado em vez de colunas, e nenhum texto '
    'some',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit, size: const Size(700, 1000));

      expect(find.byType(VersionCompareFullscreenShell), findsOneWidget);
      expect(find.byType(VersionCompareWindowedShell), findsNothing);
      expect(find.text('Somente no rascunho'), findsOneWidget);
      expect(find.text('Somente na versão'), findsNothing);

      await tester.tap(find.text('Versão'));
      await tester.pumpAndSettle();

      expect(find.text('Somente na versão'), findsOneWidget);
    },
  );
}
