import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
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
  late EditorCubit editorCubit;

  const draftSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(id: 'nd_a', type: 'text', properties: {'data': 'rascunho a'}),
        SduiNode(id: 'nd_b', type: 'text', properties: {'data': 'só base'}),
      ],
    ),
  );

  const candidateSpec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(
          id: 'nd_a',
          type: 'text',
          properties: {'data': 'candidata a'},
        ),
        SduiNode(id: 'nd_c', type: 'text', properties: {'data': 'só cand.'}),
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
    root: SduiNode(id: 'nd_root', type: 'text', properties: {'data': 'ar'}),
  );

  final publishedLoaded = LoadedContentVersion(
    version: 2,
    spec: publishedSpec,
    createdAt: DateTime.utc(2026, 8, 10),
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

  VersionCompareCubit buildCompareCubit() => VersionCompareCubit(
    getContentVersionUseCase: getContentVersion,
    editorCubit: editorCubit,
    contentId: 'ct_1',
    candidateVersion: 5,
  );

  group('load', () {
    blocTest<VersionCompareCubit, VersionCompareState>(
      'compara com o rascunho por padrão e reporta as diferenças reais',
      setUp: () {
        editorCubit = buildEditorCubit(draftSpec);
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
      },
      build: buildCompareCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionCompareLoading(),
        VersionCompareLoaded(
          candidate: candidate,
          base: VersionComparisonBase.draft,
          baseSpec: draftSpec,
          result: compareContentSpecs(draftSpec, candidateSpec),
        ),
      ],
      verify: (_) {
        final result = compareContentSpecs(draftSpec, candidateSpec);
        final comparison = result.getRight().toNullable()!;
        expect(comparison.nodesOnlyInBase, {'nd_b'});
        expect(comparison.nodesOnlyInCandidate, {'nd_c'});
        expect(
          comparison.nodeDiffs
              .singleWhere((d) => d.nodeId == 'nd_a')
              .propertiesChanged,
          isTrue,
        );
      },
    );

    blocTest<VersionCompareCubit, VersionCompareState>(
      '404: mostra o estado de erro em vez de travar em Loading',
      setUp: () {
        editorCubit = buildEditorCubit(draftSpec);
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));
      },
      build: buildCompareCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionCompareLoading(),
        const VersionCompareLoadFailure(failure: NotFoundFailure()),
      ],
    );

    blocTest<VersionCompareCubit, VersionCompareState>(
      'ID duplicado: reporta a falha tipada em vez de um diff',
      setUp: () {
        editorCubit = buildEditorCubit(duplicateSpec);
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
      },
      build: buildCompareCubit,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final state = cubit.state as VersionCompareLoaded;
        expect(state.result.isLeft(), isTrue);
        expect(
          state.result.getLeft().toNullable(),
          isA<DuplicateNodeIdComparisonFailure>(),
        );
      },
    );
  });

  group('useBase', () {
    blocTest<VersionCompareCubit, VersionCompareState>(
      'sem versão publicada: ignora o pedido de trocar para "no ar"',
      setUp: () {
        editorCubit = buildEditorCubit(draftSpec);
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
      },
      build: buildCompareCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.useBase(VersionComparisonBase.published);
      },
      verify: (cubit) {
        final state = cubit.state as VersionCompareLoaded;
        expect(state.base, VersionComparisonBase.draft);
        verifyNever(() => getContentVersion('ct_1', 2));
      },
    );

    blocTest<VersionCompareCubit, VersionCompareState>(
      'com versão publicada: busca uma vez só e usa cache da segunda em '
      'diante',
      setUp: () {
        editorCubit = buildEditorCubit(
          draftSpec,
          publication: const PublicationState(
            publishedVersion: 2,
            hasUnpublishedChanges: false,
          ),
        );
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
        when(
          () => getContentVersion('ct_1', 2),
        ).thenAnswer((_) async => Right(publishedLoaded));
      },
      build: buildCompareCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.useBase(VersionComparisonBase.published);
        await cubit.useBase(VersionComparisonBase.draft);
        await cubit.useBase(VersionComparisonBase.published);
      },
      verify: (cubit) {
        final state = cubit.state as VersionCompareLoaded;
        expect(state.base, VersionComparisonBase.published);
        expect(state.baseSpec, publishedSpec);
        verify(() => getContentVersion('ct_1', 2)).called(1);
      },
    );
  });

  group('copyNodeProperties', () {
    blocTest<VersionCompareCubit, VersionCompareState>(
      'aplica no EditorCubit e o novo rascunho volta a comparar igual '
      '(sem propertiesChanged)',
      setUp: () {
        editorCubit = buildEditorCubit(draftSpec);
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
      },
      build: buildCompareCubit,
      act: (cubit) async {
        await cubit.load();
        cubit.copyNodeProperties('nd_a');
      },
      verify: (cubit) {
        final editorState = editorCubit.state as EditorReady;
        expect(editorState.saveStatus, SaveStatus.dirty);
        expect(editorState.canUndo, isTrue);
        final updatedNode = findNode(editorState.document.root!, 'nd_a')!;
        expect(updatedNode.properties, {'data': 'candidata a'});

        final state = cubit.state as VersionCompareLoaded;
        final comparison = state.result.getRight().toNullable()!;
        expect(
          comparison.nodeDiffs
              .singleWhere((d) => d.nodeId == 'nd_a')
              .propertiesChanged,
          isFalse,
        );
      },
    );

    blocTest<VersionCompareCubit, VersionCompareState>(
      'base "no ar": recusa copiar e não toca o rascunho',
      setUp: () {
        editorCubit = buildEditorCubit(
          draftSpec,
          publication: const PublicationState(
            publishedVersion: 2,
            hasUnpublishedChanges: false,
          ),
        );
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
        when(
          () => getContentVersion('ct_1', 2),
        ).thenAnswer((_) async => Right(publishedLoaded));
      },
      build: buildCompareCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.useBase(VersionComparisonBase.published);
        final before = editorCubit.state;
        cubit.copyNodeProperties('nd_a');
        expect(editorCubit.state, before);
      },
      verify: (cubit) {
        final editorState = editorCubit.state as EditorReady;
        expect(editorState.document, draftSpec);
        expect(editorState.canUndo, isFalse);
      },
    );

    blocTest<VersionCompareCubit, VersionCompareState>(
      'ID duplicado: copiar não muda o rascunho (o motor puro recusa)',
      setUp: () {
        editorCubit = buildEditorCubit(duplicateSpec);
        when(
          () => getContentVersion('ct_1', 5),
        ).thenAnswer((_) async => Right(candidate));
      },
      build: buildCompareCubit,
      act: (cubit) async {
        await cubit.load();
        cubit.copyNodeProperties('nd_a');
      },
      verify: (cubit) {
        final editorState = editorCubit.state as EditorReady;
        expect(editorState.document, duplicateSpec);
        expect(editorState.canUndo, isFalse);
      },
    );
  });
}
