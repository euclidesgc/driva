import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
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

  EditorCubit build() => EditorCubit(
    loadContentUseCase: loadContent,
    saveDraftUseCase: saveDraft,
    projectId: 'p1',
  );

  EditorCubit buildLoaded() {
    final cubit = build()..emit(const EditorReady(document: content));
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
        cubit
          ..selectNode('nd_banner')
          ..addNode('text');
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
        cubit
          ..selectNode('nd_text')
          ..addNode('divider');
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
      'moveNodeAt reordena dentro da raiz (fresta da árvore)',
      build: buildLoaded,
      act: (cubit) => cubit.moveNodeAt('nd_text', 'nd_root', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.id), [
          'nd_text',
          'nd_banner',
        ]);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNode da raiz para dentro dela mesma só avisa, não muda o documento',
      build: buildLoaded,
      act: (cubit) => cubit.moveNode('nd_root', 'nd_banner'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.notice?.kind, EditorNoticeKind.rootNotMovable);
        expect(state.saveStatus, SaveStatus.saved);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNode em alvo folha sobe para o ancestral e avisa o desvio',
      build: buildLoaded,
      act: (cubit) => cubit.moveNode('nd_banner', 'nd_text'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.id), [
          'nd_text',
          'nd_banner',
        ]);
        expect(state.notice?.kind, EditorNoticeKind.dropRedirected);
        expect(state.notice?.subjectType, 'text');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'removeNode limpa a seleção do nó removido',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..removeNode('nd_text');
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
        cubit
          ..selectNode('nd_root')
          ..removeNode('nd_root');
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
        cubit
          ..updateProps('nd_text', {'fontSize': 20.0})
          ..updateProps('nd_text', {'data': null});
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final text = findNode(state.document.root!, 'nd_text')!;
        expect(text.properties['fontSize'], 20.0);
        expect(text.properties.containsKey('data'), isFalse);
      },
    );
  });

  group('encaixe por índice (frestas da árvore)', () {
    blocTest<EditorCubit, EditorState>(
      'addNodeAt insere na posição pedida e seleciona o novo nó',
      build: buildLoaded,
      act: (cubit) => cubit.addNodeAt('divider', 'nd_root', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.type), [
          'divider',
          'container',
          'text',
        ]);
        expect(state.selectedNodeId, state.document.root!.children.first.id);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'addNodeAt em pai que não aceita lista só avisa',
      build: buildLoaded,
      act: (cubit) => cubit.addNodeAt('divider', 'nd_text', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.notice?.kind, EditorNoticeKind.dropNoSlot);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNodeAt leva o nó para o começo da lista',
      build: buildLoaded,
      act: (cubit) => cubit.moveNodeAt('nd_text', 'nd_root', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.id), [
          'nd_text',
          'nd_banner',
        ]);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNodeAt para dentro da própria subárvore só avisa',
      build: buildLoaded,
      act: (cubit) => cubit.moveNodeAt('nd_banner', 'nd_banner', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.notice?.kind, EditorNoticeKind.dropCycle);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'moveNodeAt da raiz só avisa',
      build: buildLoaded,
      act: (cubit) => cubit.moveNodeAt('nd_root', 'nd_root', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.notice?.kind, EditorNoticeKind.rootNotMovable);
      },
    );
  });

  group('área segura da página', () {
    blocTest<EditorCubit, EditorState>(
      'updateSafeAreaProps faz merge e marca não salvo',
      build: buildLoaded,
      act: (cubit) => cubit.updateSafeAreaProps({'enabled': false}),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.safeArea, {'enabled': false});
        expect(state.saveStatus, SaveStatus.dirty);
        expect(state.document.root, content.root);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'valor null volta a prop ao padrão (remove a chave)',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..updateSafeAreaProps({'top': false})
          ..updateSafeAreaProps({'top': null});
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.safeArea, isEmpty);
      },
    );
  });

  group('diagnósticos derivados do documento', () {
    blocTest<EditorCubit, EditorState>(
      'spacer solto fora de um flex aparece como erro',
      build: buildLoaded,
      act: (cubit) => cubit.addNode('spacer', targetId: 'nd_banner'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.diagnostics, hasLength(1));
        expect(
          state.diagnostics.single.code,
          DiagnosticCode.flexOnlyOutsideFlex,
        );
      },
    );

    blocTest<EditorCubit, EditorState>(
      'documento saudável não tem diagnóstico',
      build: buildLoaded,
      act: (cubit) => cubit.addNode('text'),
      verify: (cubit) {
        expect((cubit.state as EditorReady).diagnostics, isEmpty);
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
      final cubit = build()..emit(const EditorReady(document: emptyContent));
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
        cubit
          ..moveNode('x', 'y')
          ..removeNode('x')
          ..updateProps('x', {'a': 1});
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
      final cubit = build()..emit(EditorReady(document: document));
      return cubit;
    }

    blocTest<EditorCubit, EditorState>(
      'addNode em raiz folha não cria children inválido, só avisa',
      build: () => buildWith(leafRootContent),
      act: (cubit) => cubit.addNode('button', targetId: 'nd_root_text'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, leafRootContent);
        expect(state.notice?.kind, EditorNoticeKind.dropNoSlot);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'addNode em raiz single já ocupada não cria sibling inválido, só avisa',
      build: () => buildWith(occupiedSingleRootContent),
      act: (cubit) => cubit.addNode('button', targetId: 'nd_root_container'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, occupiedSingleRootContent);
        expect(state.notice?.kind, EditorNoticeKind.dropNoSlot);
      },
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
        const EditorReady(document: content),
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
        cubit
          ..changeDevice(DevicePreset.tablet)
          ..changeZoom(9);
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.device, DevicePreset.tablet);
        expect(state.zoom, 1.5);
      },
    );
  });
}
