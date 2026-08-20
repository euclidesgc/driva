import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_copy_arrow_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_fullscreen_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_windowed_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_readonly_badge.dart';
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

  const publishedSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'text',
      properties: {'data': 'no ar!!'},
    ),
  );

  final publishedLoaded = LoadedContentVersion(
    version: 2,
    spec: publishedSpec,
    createdAt: DateTime.utc(2026, 8, 10),
  );

  setUp(() {
    loadContent = MockLoadContentUseCase();
    saveDraft = MockSaveDraftUseCase();
    publishContent = MockPublishContentUseCase();
    unpublishContent = MockUnpublishContentUseCase();
    restoreContentVersion = MockRestoreContentVersionUseCase();
    getContentVersion = MockGetContentVersionUseCase();
  });

  EditorCubit buildEditorCubit(
    ContentSpec document, {
    PublicationState publication = const PublicationState(
      hasUnpublishedChanges: true,
    ),
  }) => EditorCubit(
    loadContentUseCase: loadContent,
    saveDraftUseCase: saveDraft,
    publishContentUseCase: publishContent,
    unpublishContentUseCase: unpublishContent,
    restoreContentVersionUseCase: restoreContentVersion,
    projectId: 'p1',
  )..emit(EditorReady(document: document, publication: publication));

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
      expect(find.text('rascunho'), findsOneWidget);
      expect(find.text('candidata'), findsOneWidget);

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
      verifyZeroInteractions(saveDraft);
      verifyZeroInteractions(restoreContentVersion);
      verifyZeroInteractions(publishContent);
      verifyZeroInteractions(unpublishContent);

      expect(find.text('rascunho'), findsNothing);
      expect(find.text('candidata'), findsNWidgets(2));

      editorCubit.undo();
      await tester.pumpAndSettle();
      final afterUndo = editorCubit.state as EditorReady;
      expect(afterUndo.document, draftSpec);
      expect(find.text('rascunho'), findsOneWidget);
      expect(find.text('candidata'), findsOneWidget);
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

      await tester.tap(find.text('Candidata'));
      await tester.pumpAndSettle();

      expect(find.text('Somente na versão'), findsOneWidget);
    },
  );

  testWidgets(
    'trocar a base para "no ar" troca o spec exibido à esquerda, sem mexer '
    'na direita',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      when(
        () => getContentVersion('ct_1', 2),
      ).thenAnswer((_) async => Right(publishedLoaded));
      final editorCubit = buildEditorCubit(
        draftSpec,
        publication: const PublicationState(
          publishedVersion: 2,
          hasUnpublishedChanges: false,
        ),
      );
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);
      expect(find.text('rascunho'), findsOneWidget);
      expect(find.text('no ar!!'), findsNothing);
      expect(find.text('candidata'), findsOneWidget);
      expect(find.byType(VersionReadonlyBadge), findsOneWidget);

      await tester.tap(find.text('No ar'));
      await tester.pumpAndSettle();

      expect(find.text('no ar!!'), findsOneWidget);
      expect(find.text('rascunho'), findsNothing);
      expect(find.text('candidata'), findsOneWidget);
      expect(find.byType(VersionReadonlyBadge), findsNWidgets(2));
    },
  );

  testWidgets(
    'compacto: o preview segue o mesmo alternador da seção de nós '
    'exclusivos',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit, size: const Size(700, 1000));

      expect(find.text('rascunho'), findsOneWidget);
      expect(find.text('candidata'), findsNothing);

      await tester.tap(find.text('Candidata'));
      await tester.pumpAndSettle();

      expect(find.text('rascunho'), findsNothing);
      expect(find.text('candidata'), findsOneWidget);
    },
  );

  testWidgets(
    'desktop: base fica à esquerda e candidata à direita, nos previews e '
    'nos nós exclusivos',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);

      expect(
        tester.getTopLeft(find.text('rascunho')).dx,
        lessThan(tester.getTopLeft(find.text('candidata')).dx),
      );
      expect(
        tester.getTopLeft(find.text('nd_onlybase (text)')).dx,
        lessThan(tester.getTopLeft(find.text('nd_onlycandidate (text)')).dx),
      );
    },
  );

  testWidgets(
    'diagnósticos são reexecutados depois da cópia: o bloqueio de '
    'publicar continua correto, sem desfazer a cópia escondido',
    (tester) async {
      const draftWithError = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_4',
        name: 'Diag',
        slug: 'diag',
        root: SduiNode(
          id: 'nd_root',
          type: 'container',
          child: SduiNode(
            id: 'nd_expanded',
            type: 'expanded',
            properties: {'flex': 1},
          ),
        ),
      );
      const candidateWithError = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_4',
        name: 'Diag',
        slug: 'diag',
        root: SduiNode(
          id: 'nd_root',
          type: 'container',
          child: SduiNode(
            id: 'nd_expanded',
            type: 'expanded',
            properties: {'flex': 2},
          ),
        ),
      );
      final diagCandidate = LoadedContentVersion(
        version: 9,
        spec: candidateWithError,
        createdAt: DateTime.utc(2026, 8, 16),
      );
      when(
        () => getContentVersion('ct_4', 9),
      ).thenAnswer((_) async => Right(diagCandidate));
      final editorCubit = buildEditorCubit(draftWithError);
      addTearDown(editorCubit.close);

      final before = editorCubit.state as EditorReady;
      expect(before.publishBlockReason, PublishBlockReason.documentErrors);
      expect(before.canPublish, isFalse);

      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final compareCubit = VersionCompareCubit(
        getContentVersionUseCase: getContentVersion,
        editorCubit: editorCubit,
        contentId: 'ct_4',
        candidateVersion: 9,
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

      await tester.ensureVisible(find.byType(VersionCompareCopyArrowButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(VersionCompareCopyArrowButton));
      await tester.pumpAndSettle();

      final afterCopy = editorCubit.state as EditorReady;
      expect(
        findNode(afterCopy.document.root!, 'nd_expanded')!.properties,
        {'flex': 2},
      );
      expect(afterCopy.publishBlockReason, PublishBlockReason.documentErrors);
      expect(afterCopy.canPublish, isFalse);
    },
  );

  testWidgets(
    'cada marcador usa o ícone e a cor do seu tipo, e a declaração de '
    'somente leitura é texto visível, não só tooltip/semantics',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(candidate));
      final editorCubit = buildEditorCubit(draftSpec);
      addTearDown(editorCubit.close);

      await pumpDialog(tester, editorCubit);

      final colors = AppTheme.light.extension<EditorColors>()!;
      Color iconColorFor(IconData icon) =>
          tester.widget<Icon>(find.byIcon(icon)).color!;

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(iconColorFor(Icons.tune), colors.success);

      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
      expect(iconColorFor(Icons.bolt_outlined), colors.warning);

      expect(find.byIcon(Icons.crop_free), findsOneWidget);
      expect(iconColorFor(Icons.crop_free), colors.warning);

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(iconColorFor(Icons.info_outline), colors.warning);

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(iconColorFor(Icons.remove_circle_outline), colors.warning);

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(iconColorFor(Icons.add_circle_outline), colors.warning);

      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(iconColorFor(Icons.swap_horiz), colors.danger);

      expect(find.text('(somente leitura)'), findsNWidgets(3));
    },
  );

  group('banner "carregar versão inteira" isola cada causa', () {
    const bannerBase = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_3',
      name: 'Base',
      slug: 'base',
      root: SduiNode(
        id: 'nd_root',
        type: 'column',
        children: [
          SduiNode(id: 'nd_a', type: 'text', properties: {'data': 'a'}),
        ],
      ),
    );

    Future<void> pumpReason(
      WidgetTester tester,
      ContentSpec candidateForReason,
    ) async {
      final loaded = LoadedContentVersion(
        version: 9,
        spec: candidateForReason,
        createdAt: DateTime.utc(2026, 8, 16),
      );
      when(
        () => getContentVersion('ct_3', 9),
      ).thenAnswer((_) async => Right(loaded));
      final editorCubit = buildEditorCubit(bannerBase);
      addTearDown(editorCubit.close);

      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final compareCubit = VersionCompareCubit(
        getContentVersionUseCase: getContentVersion,
        editorCubit: editorCubit,
        contentId: 'ct_3',
        candidateVersion: 9,
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
    }

    String bannerTextFor(String reason) =>
        'Esta versão tem diferenças que a seta não alcança ($reason). '
        'Para trazê-las, carregue a versão inteira.';

    testWidgets('estrutura: nó só de um lado', (tester) async {
      const reasonCandidate = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_3',
        name: 'Base',
        slug: 'base',
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [
            SduiNode(id: 'nd_a', type: 'text', properties: {'data': 'a'}),
            SduiNode(id: 'nd_b', type: 'text'),
          ],
        ),
      );
      await pumpReason(tester, reasonCandidate);

      expect(find.text(bannerTextFor('estrutura')), findsOneWidget);
    });

    testWidgets('tipo: mesmo nó, tipo diferente', (tester) async {
      const reasonCandidate = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_3',
        name: 'Base',
        slug: 'base',
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [SduiNode(id: 'nd_a', type: 'container')],
        ),
      );
      await pumpReason(tester, reasonCandidate);

      expect(find.text(bannerTextFor('tipo')), findsOneWidget);
    });

    testWidgets('eventos: mesmo nó e tipo, evento diferente', (tester) async {
      const reasonCandidate = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_3',
        name: 'Base',
        slug: 'base',
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [
            SduiNode(
              id: 'nd_a',
              type: 'text',
              properties: {'data': 'a'},
              events: {
                'onTap': {'action': 'go'},
              },
            ),
          ],
        ),
      );
      await pumpReason(tester, reasonCandidate);

      expect(find.text(bannerTextFor('eventos')), findsOneWidget);
    });

    testWidgets('safe area: safeArea do spec diferente', (tester) async {
      const reasonCandidate = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_3',
        name: 'Base',
        slug: 'base',
        safeArea: {'top': true},
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [
            SduiNode(id: 'nd_a', type: 'text', properties: {'data': 'a'}),
          ],
        ),
      );
      await pumpReason(tester, reasonCandidate);

      expect(find.text(bannerTextFor('safe area')), findsOneWidget);
    });

    testWidgets('metadados: nome do conteúdo diferente', (tester) async {
      const reasonCandidate = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_3',
        name: 'Base v2',
        slug: 'base',
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [
            SduiNode(id: 'nd_a', type: 'text', properties: {'data': 'a'}),
          ],
        ),
      );
      await pumpReason(tester, reasonCandidate);

      expect(find.text(bannerTextFor('metadados')), findsOneWidget);
    });

    testWidgets(
      'nenhuma causa: só propriedade copiável mudou, banner não aparece',
      (tester) async {
        const reasonCandidate = ContentSpec(
          specVersion: kSpecVersion,
          id: 'ct_3',
          name: 'Base',
          slug: 'base',
          root: SduiNode(
            id: 'nd_root',
            type: 'column',
            children: [
              SduiNode(id: 'nd_a', type: 'text', properties: {'data': 'b'}),
            ],
          ),
        );
        await pumpReason(tester, reasonCandidate);

        expect(
          find.textContaining('Esta versão tem diferenças que a seta não'),
          findsNothing,
        );
      },
    );
  });

  testWidgets(
    'trocar a base para "no ar" troca os rótulos que diziam "rascunho" '
    'para nomear a versão publicada',
    (tester) async {
      const draftForLabels = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_5',
        name: 'Home',
        slug: 'home',
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [SduiNode(id: 'nd_only_draft', type: 'text')],
        ),
      );
      const publishedForLabels = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_5',
        name: 'Home',
        slug: 'home',
        root: SduiNode(
          id: 'nd_root',
          type: 'column',
          children: [SduiNode(id: 'nd_only_published', type: 'text')],
        ),
      );
      const candidateForLabels = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_5',
        name: 'Home v2',
        slug: 'home',
        root: SduiNode(id: 'nd_root', type: 'column'),
      );
      final labelsCandidate = LoadedContentVersion(
        version: 6,
        spec: candidateForLabels,
        createdAt: DateTime.utc(2026, 8, 16),
      );
      final labelsPublished = LoadedContentVersion(
        version: 2,
        spec: publishedForLabels,
        createdAt: DateTime.utc(2026, 8, 10),
      );
      when(
        () => getContentVersion('ct_5', 6),
      ).thenAnswer((_) async => Right(labelsCandidate));
      when(
        () => getContentVersion('ct_5', 2),
      ).thenAnswer((_) async => Right(labelsPublished));
      final editorCubit = buildEditorCubit(
        draftForLabels,
        publication: const PublicationState(
          publishedVersion: 2,
          hasUnpublishedChanges: false,
        ),
      );
      addTearDown(editorCubit.close);

      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final compareCubit = VersionCompareCubit(
        getContentVersionUseCase: getContentVersion,
        editorCubit: editorCubit,
        contentId: 'ct_5',
        candidateVersion: 6,
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

      expect(find.text('Somente no rascunho'), findsOneWidget);
      expect(find.text('Rascunho'), findsNWidgets(2));

      await tester.tap(find.text('No ar'));
      await tester.pumpAndSettle();

      expect(find.text('Somente no rascunho'), findsNothing);
      expect(find.text('Rascunho'), findsOneWidget);
      expect(find.text('Somente em v2 (no ar)'), findsOneWidget);
      expect(find.text('v2 (no ar)'), findsOneWidget);
    },
  );
}
