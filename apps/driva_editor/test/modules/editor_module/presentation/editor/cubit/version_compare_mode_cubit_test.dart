import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

class MockEditorCubit extends MockCubit<EditorState> implements EditorCubit {}

class MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class MockPublishContentUseCase extends Mock implements PublishContentUseCase {}

class MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

ContentSpec _specWithText(String text) => ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'n_root',
    type: 'text',
    properties: {'text': text},
  ),
);

void main() {
  late MockGetContentVersionUseCase getVersion;
  late MockGetContentVersionsUseCase getVersions;
  late MockEditorCubit editorCubit;
  late StreamController<EditorState> editorStates;

  final draftSpec = _specWithText('rascunho ao vivo');
  final v3Spec = _specWithText('como era na v3');
  final v2Spec = _specWithText('como era na v2');

  final v3 = LoadedContentVersion(
    version: 3,
    spec: v3Spec,
    createdAt: DateTime.utc(2026, 8, 16),
    note: 'Ajuste no banner',
  );
  final v2 = LoadedContentVersion(
    version: 2,
    spec: v2Spec,
    createdAt: DateTime.utc(2026, 8, 15),
  );
  final v1 = LoadedContentVersion(
    version: 1,
    spec: _specWithText('como era na v1'),
    createdAt: DateTime.utc(2026, 8, 14),
  );

  final page = ContentVersionsPage(
    items: [
      ContentVersion(version: 3, createdAt: DateTime.utc(2026, 8, 16)),
      ContentVersion(version: 2, createdAt: DateTime.utc(2026, 8, 15)),
      ContentVersion(version: 1, createdAt: DateTime.utc(2026, 8, 14)),
    ],
  );

  EditorReady ready({
    ContentSpec? document,
    SaveStatus saveStatus = SaveStatus.saved,
  }) => EditorReady(
    document: document ?? draftSpec,
    saveStatus: saveStatus,
  );

  setUpAll(() {
    registerFallbackValue(draftSpec);
  });

  setUp(() {
    getVersion = MockGetContentVersionUseCase();
    getVersions = MockGetContentVersionsUseCase();
    editorCubit = MockEditorCubit();
    editorStates = StreamController<EditorState>.broadcast();

    when(() => editorCubit.state).thenReturn(ready());
    whenListen(editorCubit, editorStates.stream);

    when(() => getVersion('ct_1', 3)).thenAnswer((_) async => Right(v3));
    when(() => getVersion('ct_1', 2)).thenAnswer((_) async => Right(v2));
    when(() => getVersion('ct_1', 1)).thenAnswer((_) async => Right(v1));
    when(
      () => getVersions('ct_1', cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => Right(page));
  });

  tearDown(() => editorStates.close());

  VersionCompareModeCubit build() => VersionCompareModeCubit(
    getContentVersionUseCase: getVersion,
    getContentVersionsUseCase: getVersions,
    editorCubit: editorCubit,
  );

  group('enter', () {
    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'sucesso: Loading e depois Active com a candidata pedida e o rascunho '
      'ao vivo como base',
      build: build,
      act: (cubit) => cubit.enter(3),
      expect: () => [
        const VersionCompareModeLoading(candidateVersion: 3),
        isA<VersionCompareModeActive>()
            .having((s) => s.candidate.version, 'candidate.version', 3)
            .having((s) => s.baseSpec, 'baseSpec', draftSpec)
            .having((s) => s.versions.length, 'versions.length', 3),
      ],
      verify: (_) => verify(() => getVersion('ct_1', 3)).called(1),
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'falha do detalhe: para em Failure sem tocar no documento do editor',
      build: build,
      setUp: () => when(
        () => getVersion('ct_1', 3),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.enter(3),
      expect: () => [
        const VersionCompareModeLoading(candidateVersion: 3),
        const VersionCompareModeFailure(
          failure: NetworkFailure(),
          candidateVersion: 3,
        ),
      ],
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'falha só da lista: o modo abre mesmo assim, com histórico vazio',
      build: build,
      setUp: () => when(
        () => getVersions('ct_1', cursor: any(named: 'cursor')),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.enter(3),
      expect: () => [
        const VersionCompareModeLoading(candidateVersion: 3),
        isA<VersionCompareModeActive>()
            .having((s) => s.candidate.version, 'candidate.version', 3)
            .having((s) => s.versions, 'versions', isEmpty),
      ],
    );
  });

  group('selectVersion', () {
    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'troca só a candidata: a base continua sendo o rascunho ao vivo',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        await cubit.selectVersion(2);
      },
      skip: 2,
      expect: () => [
        isA<VersionCompareModeActive>()
            .having((s) => s.candidate.version, 'candidate.version', 2)
            .having((s) => s.candidate.spec, 'candidate.spec', v2Spec)
            .having((s) => s.baseSpec, 'baseSpec', draftSpec),
      ],
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'escolher a candidata já exibida não emite nem requisita de novo',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        await cubit.selectVersion(3);
      },
      skip: 2,
      expect: () => <VersionCompareModeState>[],
      verify: (_) => verify(() => getVersion('ct_1', 3)).called(1),
    );
  });

  group('stepOlder e stepNewer', () {
    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'stepOlder anda para a versão anterior da lista',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        await cubit.stepOlder();
      },
      skip: 2,
      expect: () => [
        isA<VersionCompareModeActive>().having(
          (s) => s.candidate.version,
          'candidate.version',
          2,
        ),
      ],
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'stepNewer na versão mais nova não emite: não há para onde ir',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        await cubit.stepNewer();
      },
      skip: 2,
      expect: () => <VersionCompareModeState>[],
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'stepOlder desce até a mais antiga e para: sem cursor, não há próxima '
      'página para pedir',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        await cubit.stepOlder();
        await cubit.stepOlder();
        await cubit.stepOlder();
      },
      skip: 3,
      expect: () => [
        isA<VersionCompareModeActive>().having(
          (s) => s.candidate.version,
          'candidate.version',
          1,
        ),
      ],
      verify: (_) => verify(() => getVersion('ct_1', 1)).called(1),
    );
  });

  group('sincronização com o rascunho ao vivo', () {
    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'documento novo do editor atualiza a base e recalcula a comparação',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        final edited = _specWithText('acabei de digitar');
        when(() => editorCubit.state).thenReturn(ready(document: edited));
        editorStates.add(ready(document: edited));
        await Future<void>.delayed(Duration.zero);
      },
      skip: 2,
      expect: () => [
        isA<VersionCompareModeActive>()
            .having(
              (s) => s.baseSpec.root!.properties['text']! as String,
              'texto da base',
              'acabei de digitar',
            )
            .having((s) => s.candidate.version, 'candidate.version', 3),
      ],
    );
  });

  group('saída do modo', () {
    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'exit volta a Inactive sem reverter o documento do editor',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        cubit.exit();
      },
      skip: 2,
      expect: () => [const VersionCompareModeInactive()],
      verify: (_) => expect(
        (editorCubit.state as EditorReady).document,
        draftSpec,
        reason: 'sair da comparação não muta o documento do editor',
      ),
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'entrar congela o rascunho e fechar o descongela',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        cubit.exit();
      },
      verify: (_) {
        verify(() => editorCubit.setReadOnly(value: true)).called(1);
        verify(() => editorCubit.setReadOnly(value: false)).called(1);
      },
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'documento do editor mudando não encerra o modo — só atualiza a base '
      'comparada',
      build: build,
      act: (cubit) async {
        await cubit.enter(3);
        final undone = _specWithText('depois do Ctrl+Z');
        when(() => editorCubit.state).thenReturn(ready(document: undone));
        editorStates.add(ready(document: undone));
        await Future<void>.delayed(Duration.zero);
      },
      skip: 2,
      expect: () => [isA<VersionCompareModeActive>()],
    );

    blocTest<VersionCompareModeCubit, VersionCompareModeState>(
      'exit fora do modo não emite',
      build: build,
      act: (cubit) => cubit.exit(),
      expect: () => <VersionCompareModeState>[],
    );
  });

  group('returnToPublished', () {
    late EditorCubit realEditorCubit;

    EditorReady readyPublished({int? publishedVersion = 2}) => EditorReady(
      document: draftSpec,
      publication: PublicationState(
        hasUnpublishedChanges: true,
        publishedVersion: publishedVersion,
      ),
    );

    setUp(() {
      realEditorCubit = EditorCubit(
        loadContentUseCase: MockLoadContentUseCase(),
        saveDraftUseCase: MockSaveDraftUseCase(),
        publishContentUseCase: MockPublishContentUseCase(),
        unpublishContentUseCase: MockUnpublishContentUseCase(),
        restoreContentVersionUseCase: MockRestoreContentVersionUseCase(),
        projectId: 'p1',
      );
    });

    tearDown(() => realEditorCubit.close());

    VersionCompareModeCubit buildWithRealEditor() => VersionCompareModeCubit(
      getContentVersionUseCase: getVersion,
      getContentVersionsUseCase: getVersions,
      editorCubit: realEditorCubit,
    );

    VersionCompareModeActive activeWith(LoadedContentVersion candidate) =>
        VersionCompareModeActive(
          candidate: candidate,
          baseSpec: draftSpec,
          result: compareContentSpecs(draftSpec, candidate.spec),
          versions: page.items,
        );

    test('candidata já é a publicada: aplica o spec dela sem nova '
        'requisição', () async {
      realEditorCubit.emit(readyPublished());
      final cubit = buildWithRealEditor()..emit(activeWith(v2));

      final ok = await cubit.returnToPublished();

      expect(ok, isTrue);
      final state = realEditorCubit.state as EditorReady;
      expect(state.document, v2Spec);
      verifyNever(() => getVersion(any(), any()));
      await cubit.close();
    });

    test(
      'candidata diferente da publicada: busca a publicada e aplica',
      () async {
        realEditorCubit.emit(readyPublished());
        final cubit = buildWithRealEditor()..emit(activeWith(v3));

        final ok = await cubit.returnToPublished();

        expect(ok, isTrue);
        verify(() => getVersion('ct_1', 2)).called(1);
        final state = realEditorCubit.state as EditorReady;
        expect(state.document, v2Spec);
        await cubit.close();
      },
    );

    test(
      'sem versão publicada: devolve false e o documento não muda',
      () async {
        realEditorCubit.emit(readyPublished(publishedVersion: null));
        final cubit = buildWithRealEditor()..emit(activeWith(v3));

        final ok = await cubit.returnToPublished();

        expect(ok, isFalse);
        final state = realEditorCubit.state as EditorReady;
        expect(state.document, draftSpec);
        verifyNever(() => getVersion(any(), any()));
        await cubit.close();
      },
    );

    test(
      'falha ao buscar a publicada: devolve false e o documento não muda',
      () async {
        realEditorCubit.emit(readyPublished());
        when(
          () => getVersion('ct_1', 2),
        ).thenAnswer((_) async => const Left(UnexpectedFailure()));
        final cubit = buildWithRealEditor()..emit(activeWith(v3));

        final ok = await cubit.returnToPublished();

        expect(ok, isFalse);
        final state = realEditorCubit.state as EditorReady;
        expect(state.document, draftSpec);
        await cubit.close();
      },
    );

    test(
      'um único undo devolve o documento ao estado anterior à volta',
      () async {
        realEditorCubit.emit(readyPublished());
        final cubit = buildWithRealEditor()..emit(activeWith(v3));

        await cubit.returnToPublished();
        expect((realEditorCubit.state as EditorReady).document, v2Spec);

        realEditorCubit.undo();

        expect((realEditorCubit.state as EditorReady).document, draftSpec);
        await cubit.close();
      },
    );

    test('a volta ao publicado encerra o modo', () async {
      realEditorCubit.emit(readyPublished());
      final cubit = buildWithRealEditor()..emit(activeWith(v2));

      await cubit.returnToPublished();

      expect(cubit.state, isA<VersionCompareModeInactive>());
      expect((realEditorCubit.state as EditorReady).isReadOnly, isFalse);
      await cubit.close();
    });
  });

  group('aplicar a versão inteira', () {
    late EditorCubit realEditorCubit;

    setUp(() {
      realEditorCubit = EditorCubit(
        loadContentUseCase: MockLoadContentUseCase(),
        saveDraftUseCase: MockSaveDraftUseCase(),
        publishContentUseCase: MockPublishContentUseCase(),
        unpublishContentUseCase: MockUnpublishContentUseCase(),
        restoreContentVersionUseCase: MockRestoreContentVersionUseCase(),
        projectId: 'p1',
      )..emit(EditorReady(document: draftSpec));
    });

    tearDown(() => realEditorCubit.close());

    VersionCompareModeCubit buildWithRealEditor() => VersionCompareModeCubit(
      getContentVersionUseCase: getVersion,
      getContentVersionsUseCase: getVersions,
      editorCubit: realEditorCubit,
    );

    test('traz a candidata para o rascunho, encerra o modo e descongela '
        'o editor', () async {
      final cubit = buildWithRealEditor();
      await cubit.enter(3);
      expect((realEditorCubit.state as EditorReady).isReadOnly, isTrue);

      cubit.applyCandidateToDraft();

      expect(cubit.state, isA<VersionCompareModeInactive>());
      final state = realEditorCubit.state as EditorReady;
      expect(state.document, v3Spec);
      expect(state.isReadOnly, isFalse);
      await cubit.close();
    });

    test('fora do modo não faz nada', () async {
      final cubit = buildWithRealEditor()..applyCandidateToDraft();

      expect(cubit.state, isA<VersionCompareModeInactive>());
      expect((realEditorCubit.state as EditorReady).document, draftSpec);
      await cubit.close();
    });

    test('um único undo desfaz a versão aplicada', () async {
      final cubit = buildWithRealEditor();
      await cubit.enter(3);
      cubit.applyCandidateToDraft();

      realEditorCubit.undo();

      expect((realEditorCubit.state as EditorReady).document, draftSpec);
      await cubit.close();
    });
  });
}
