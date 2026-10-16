import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class MockPublishContentUseCase extends Mock implements PublishContentUseCase {}

class MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

void main() {
  const previousEvents = <String, dynamic>{
    'onLongPress': [
      {'action': 'navigateBack', 'params': <String, dynamic>{}},
    ],
  };

  const content = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [SduiNode(id: 'n1', type: 'container', events: previousEvents)],
    ),
  );

  final onTapBack = <String, List<Map<String, dynamic>>?>{
    'onTap': [
      {'action': 'navigateBack', 'params': <String, dynamic>{}},
    ],
  };

  EditorCubit build({bool isReadOnly = false}) => EditorCubit(
    loadContentUseCase: MockLoadContentUseCase(),
    saveDraftUseCase: MockSaveDraftUseCase(),
    publishContentUseCase: MockPublishContentUseCase(),
    unpublishContentUseCase: MockUnpublishContentUseCase(),
    restoreContentVersionUseCase: MockRestoreContentVersionUseCase(),
    projectId: 'p1',
  )..emit(EditorReady(document: content, isReadOnly: isReadOnly));

  SduiNode n1(EditorCubit cubit) =>
      findNode((cubit.state as EditorReady).document.root!, 'n1')!;

  group('EditorCubit.updateEvents', () {
    blocTest<EditorCubit, EditorState>(
      'grava o gatilho no nó, suja o rascunho e liga o desfazer',
      build: build,
      act: (cubit) => cubit.updateEvents('n1', onTapBack),
      expect: () => [
        isA<EditorReady>()
            .having((s) => s.saveStatus, 'saveStatus', SaveStatus.dirty)
            .having((s) => s.canUndo, 'canUndo', isTrue)
            .having(
              (s) => findNode(s.document.root!, 'n1')!.events,
              'events de n1',
              {...previousEvents, ...onTapBack},
            ),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'undo devolve o events anterior',
      build: build,
      act: (cubit) => cubit
        ..updateEvents('n1', onTapBack)
        ..undo(),
      verify: (cubit) => expect(n1(cubit).events, previousEvents),
    );

    blocTest<EditorCubit, EditorState>(
      'null remove o gatilho do nó',
      build: build,
      act: (cubit) => cubit
        ..updateEvents('n1', onTapBack)
        ..updateEvents('n1', {'onTap': null}),
      verify: (cubit) {
        expect(n1(cubit).events, isNot(contains('onTap')));
        expect(n1(cubit).events, previousEvents);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'null no único gatilho deixa o nó sem events',
      build: build,
      act: (cubit) => cubit.updateEvents('n1', {'onLongPress': null}),
      verify: (cubit) => expect(n1(cubit).events, isEmpty),
    );

    blocTest<EditorCubit, EditorState>(
      'o mesmo coalesceKey vira uma entrada só de desfazer',
      build: build,
      act: (cubit) => cubit
        ..updateEvents(
          'n1',
          {
            'onTap': [
              {
                'action': 'showSnackBar',
                'params': {'message': 'O'},
              },
            ],
          },
          coalesceKey: 'events:n1:onTap:message',
        )
        ..updateEvents(
          'n1',
          {
            'onTap': [
              {
                'action': 'showSnackBar',
                'params': {'message': 'Oi'},
              },
            ],
          },
          coalesceKey: 'events:n1:onTap:message',
        )
        ..undo(),
      verify: (cubit) {
        expect(n1(cubit).events, previousEvents);
        expect((cubit.state as EditorReady).canUndo, isFalse);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'no modo só leitura não emite estado',
      build: () => build(isReadOnly: true),
      act: (cubit) => cubit.updateEvents('n1', onTapBack),
      expect: () => <EditorState>[],
    );
  });
}
