import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

void main() {
  late MockLoadContentUseCase loadContent;
  late MockSaveDraftUseCase saveDraft;

  const content = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(id: 'nd_banner', type: 'container'),
        SduiNode(id: 'nd_text', type: 'text', properties: {'data': 'Oi'}),
      ],
    ),
  );

  setUpAll(() => registerFallbackValue(content));

  setUp(() {
    loadContent = MockLoadContentUseCase();
    saveDraft = MockSaveDraftUseCase();
  });

  EditorCubit build() =>
      EditorCubit(loadContentUseCase: loadContent, saveDraftUseCase: saveDraft);

  EditorCubit buildLoaded() {
    final cubit = build();
    cubit.emit(const EditorReady(document: content));
    return cubit;
  }

  group('loadContent', () {
    blocTest<EditorCubit, EditorState>(
      'emite Loading → Ready com o documento',
      build: build,
      setUp: () => when(
        () => loadContent('ct_1'),
      ).thenAnswer((_) async => const Right(content)),
      act: (cubit) => cubit.loadContent('ct_1'),
      expect: () => [
        const EditorLoading(),
        const EditorReady(document: content),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'emite Loading → LoadFailure na falha',
      build: build,
      setUp: () => when(
        () => loadContent('ct_1'),
      ).thenAnswer((_) async => const Left(NotFoundFailure())),
      act: (cubit) => cubit.loadContent('ct_1'),
      expect: () => [
        const EditorLoading(),
        const EditorLoadFailure(failure: NotFoundFailure()),
      ],
    );
  });

  group('mutações da árvore', () {
    blocTest<EditorCubit, EditorState>(
      'addNode na raiz: nó com defaults do catálogo, selecionado, dirty',
      build: buildLoaded,
      act: (cubit) => cubit.addNode('button'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children, hasLength(3));
        final added = state.document.root!.children.last;
        expect(added.type, 'button');
        expect(added.properties['label'], 'Botão');
        expect(state.selectedNodeId, added.id);
        expect(state.saveStatus, SaveStatus.dirty);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'addNode com container selecionado entra como child (slot único)',
      build: buildLoaded,
      act: (cubit) {
        cubit.selectNode('nd_banner');
        cubit.addNode('text');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final banner = findNode(state.document.root!, 'nd_banner')!;
        expect(banner.child?.type, 'text');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'addNode com folha selecionada entra como vizinho na raiz',
      build: buildLoaded,
      act: (cubit) {
        cubit.selectNode('nd_text');
        cubit.addNode('divider');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.type), [
          'container',
          'text',
          'divider',
        ]);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNode reordena dentro da raiz',
      build: buildLoaded,
      act: (cubit) => cubit.moveNode('nd_text', 'nd_root', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.id), [
          'nd_text',
          'nd_banner',
        ]);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNode inválido (para a própria subárvore) não muda nada',
      build: buildLoaded,
      act: (cubit) => cubit.moveNode('nd_root', 'nd_banner', 0),
      expect: () => <EditorState>[],
    );

    blocTest<EditorCubit, EditorState>(
      'removeNode limpa a seleção do nó removido',
      build: buildLoaded,
      act: (cubit) {
        cubit.selectNode('nd_text');
        cubit.removeNode('nd_text');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(findNode(state.document.root!, 'nd_text'), isNull);
        expect(state.selectedNodeId, isNull);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'removeNode na raiz esvazia o conteúdo e limpa a seleção',
      build: buildLoaded,
      act: (cubit) {
        cubit.selectNode('nd_root');
        cubit.removeNode('nd_root');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root, isNull);
        expect(state.selectedNodeId, isNull);
        expect(state.saveStatus, SaveStatus.dirty);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'updateProps faz merge e null remove a chave',
      build: buildLoaded,
      act: (cubit) {
        cubit.updateProps('nd_text', {'fontSize': 20.0});
        cubit.updateProps('nd_text', {'data': null});
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final text = findNode(state.document.root!, 'nd_text')!;
        expect(text.properties['fontSize'], 20.0);
        expect(text.properties.containsKey('data'), isFalse);
      },
    );
  });

  group('conteúdo vazio (root null)', () {
    const emptyContent = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_vazio',
      name: 'Vazio',
      slug: 'vazio',
    );

    EditorCubit buildEmpty() {
      final cubit = build();
      cubit.emit(const EditorReady(document: emptyContent));
      return cubit;
    }

    blocTest<EditorCubit, EditorState>(
      'addNode com root null: o nó vira a raiz e fica selecionado',
      build: buildEmpty,
      act: (cubit) => cubit.addNode('container'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root;
        expect(root, isNotNull);
        expect(root!.type, 'container');
        expect(state.selectedNodeId, root.id);
        expect(state.saveStatus, SaveStatus.dirty);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'primeiro widget pode ser de qualquer tipo (não só column)',
      build: buildEmpty,
      act: (cubit) => cubit.addNode('text'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root?.type, 'text');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'mutações sem raiz (move/remove/updateProps) não fazem nada',
      build: buildEmpty,
      act: (cubit) {
        cubit.moveNode('x', 'y', 0);
        cubit.removeNode('x');
        cubit.updateProps('x', {'a': 1});
      },
      expect: () => <EditorState>[],
    );
  });

  group('raiz livre sem slot multi', () {
    const leafRootContent = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_leaf',
      name: 'Leaf',
      slug: 'leaf',
      root: SduiNode(id: 'nd_root_text', type: 'text'),
    );

    const occupiedSingleRootContent = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_single',
      name: 'Single',
      slug: 'single',
      root: SduiNode(
        id: 'nd_root_container',
        type: 'container',
        child: SduiNode(id: 'nd_text', type: 'text'),
      ),
    );

    EditorCubit buildWith(ContentSpec document) {
      final cubit = build();
      cubit.emit(EditorReady(document: document));
      return cubit;
    }

    blocTest<EditorCubit, EditorState>(
      'addNode em raiz folha não cria children inválido',
      build: () => buildWith(leafRootContent),
      act: (cubit) => cubit.addNode('button', parentId: 'nd_root_text'),
      expect: () => <EditorState>[],
    );

    blocTest<EditorCubit, EditorState>(
      'addNode em raiz single já ocupada não cria sibling inválido',
      build: () => buildWith(occupiedSingleRootContent),
      act: (cubit) => cubit.addNode('button', parentId: 'nd_root_container'),
      expect: () => <EditorState>[],
    );
  });

  group('save', () {
    blocTest<EditorCubit, EditorState>(
      'sucesso: saving → saved',
      build: buildLoaded,
      setUp: () => when(
        () => saveDraft(any()),
      ).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.save(),
      expect: () => [
        const EditorReady(document: content, saveStatus: SaveStatus.saving),
        const EditorReady(document: content, saveStatus: SaveStatus.saved),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'falha: saving → saveFailed, documento intacto',
      build: buildLoaded,
      setUp: () => when(
        () => saveDraft(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.save(),
      expect: () => [
        const EditorReady(document: content, saveStatus: SaveStatus.saving),
        const EditorReady(document: content, saveStatus: SaveStatus.saveFailed),
      ],
    );
  });

  group('preview', () {
    blocTest<EditorCubit, EditorState>(
      'changeDevice e changeZoom (com clamp)',
      build: buildLoaded,
      act: (cubit) {
        cubit.changeDevice(DevicePreset.tablet);
        cubit.changeZoom(9);
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.device, DevicePreset.tablet);
        expect(state.zoom, 1.5);
      },
    );
  });
}
