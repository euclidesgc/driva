import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
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

class MockPublishContentUseCase extends Mock implements PublishContentUseCase {}

class MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

void main() {
  late MockLoadContentUseCase loadContent;
  late MockSaveDraftUseCase saveDraft;
  late MockPublishContentUseCase publishContent;
  late MockUnpublishContentUseCase unpublishContent;
  late MockRestoreContentVersionUseCase restoreContentVersion;

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

  const loadedContent = LoadedContent(
    spec: content,
    publication: PublicationState(hasUnpublishedChanges: true),
  );

  const leafRootContent = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_leaf',
    name: 'Leaf',
    slug: 'leaf',
    root: SduiNode(id: 'nd_root_text', type: 'text'),
  );

  setUpAll(() => registerFallbackValue(content));

  setUp(() {
    loadContent = MockLoadContentUseCase();
    saveDraft = MockSaveDraftUseCase();
    publishContent = MockPublishContentUseCase();
    unpublishContent = MockUnpublishContentUseCase();
    restoreContentVersion = MockRestoreContentVersionUseCase();
  });

  EditorCubit build() => EditorCubit(
    loadContentUseCase: loadContent,
    saveDraftUseCase: saveDraft,
    publishContentUseCase: publishContent,
    unpublishContentUseCase: unpublishContent,
    restoreContentVersionUseCase: restoreContentVersion,
    projectId: 'p1',
  );

  EditorCubit buildWith(ContentSpec document) {
    final cubit = build()..emit(EditorReady(document: document));
    return cubit;
  }

  EditorCubit buildLoaded() => buildWith(content);

  group('rascunho congelado (modo de comparação)', () {
    EditorCubit buildFrozen() {
      final cubit = build()
        ..emit(const EditorReady(document: content, isReadOnly: true));
      return cubit;
    }

    const otherSpec = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: SduiNode(id: 'nd_v2', type: 'text'),
    );

    blocTest<EditorCubit, EditorState>(
      'nenhuma mutação da árvore atravessa o congelamento',
      build: buildFrozen,
      act: (cubit) => cubit
        ..selectNode('nd_text')
        ..addNode('container', targetId: 'nd_root')
        ..addNodeAt('text', 'nd_root', 0)
        ..moveNode('nd_text', 'nd_banner')
        ..moveNodeAt('nd_text', 'nd_root', 0)
        ..updateProps('nd_text', {'data': 'editado'})
        ..updateSafeAreaProps({'top': false})
        ..duplicateSelected()
        ..copySelected()
        ..wrapSelected('column')
        ..removeNode('nd_banner')
        ..removeSelected(),
      verify: (cubit) => expect(
        (cubit.state as EditorReady).document,
        content,
        reason: 'o documento tem de sair igual ao que entrou',
      ),
    );

    blocTest<EditorCubit, EditorState>(
      'desfazer e refazer não atravessam — a pilha fica onde estava',
      build: buildLoaded,
      act: (cubit) async {
        cubit.updateProps('nd_text', {'data': 'antes de congelar'});
        final edited = (cubit.state as EditorReady).document;
        cubit.setReadOnly(value: true);
        cubit
          ..undo()
          ..redo();
        expect((cubit.state as EditorReady).document, edited);
        cubit.setReadOnly(value: false);
        cubit.undo();
        expect((cubit.state as EditorReady).document, content);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'salvar, publicar, despublicar e restaurar não chamam o servidor',
      build: buildFrozen,
      act: (cubit) async {
        await cubit.save();
        await cubit.save(checkpointNote: 'ponto');
        await cubit.publish();
        await cubit.unpublish();
        await cubit.restoreVersion(2);
      },
      verify: (_) {
        verifyNever(
          () => saveDraft(any(), checkpointNote: any(named: 'checkpointNote')),
        );
        verifyNever(() => publishContent(any(), note: any(named: 'note')));
        verifyNever(() => unpublishContent(any()));
        verifyNever(() => restoreContentVersion(any(), any()));
      },
    );

    blocTest<EditorCubit, EditorState>(
      'carregar a versão inteira atravessa — é a saída do modo, não uma '
      'edição do usuário',
      build: buildFrozen,
      act: (cubit) => cubit.loadVersionIntoDraft(otherSpec, version: 2),
      verify: (cubit) =>
          expect((cubit.state as EditorReady).document, otherSpec),
    );

    blocTest<EditorCubit, EditorState>(
      'ler continua: seleção, zoom e dispositivo respondem congelados',
      build: buildFrozen,
      act: (cubit) => cubit
        ..selectNode('nd_text')
        ..changeZoom(1.2)
        ..changeDevice(DevicePreset.tablet)
        ..toggleFitToWindow(),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.selectedNodeId, 'nd_text');
        expect(state.zoom, 1.2);
        expect(state.device, DevicePreset.tablet);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'publicar fica bloqueado com motivo próprio, não "corrija os erros"',
      build: buildFrozen,
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.canPublish, isFalse);
        expect(
          state.publishBlockReason,
          PublishBlockReason.comparingVersions,
        );
      },
    );
  });

  group('loadContent', () {
    blocTest<EditorCubit, EditorState>(
      'emite Loading → Ready com o documento',
      build: build,
      setUp: () => when(
        () => loadContent('ct_1'),
      ).thenAnswer((_) async => const Right(loadedContent)),
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
      'addNodeAt em pai que não aceita lista converge com addNode '
      '(redireciona)',
      build: buildLoaded,
      act: (cubit) => cubit.addNodeAt('divider', 'nd_text', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.type), [
          'container',
          'text',
          'divider',
        ]);
        expect(state.notice?.kind, EditorNoticeKind.dropRedirected);
        expect(state.notice?.subjectType, 'text');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'addNodeAt com parentId inexistente segue recusando',
      build: buildLoaded,
      act: (cubit) => cubit.addNodeAt('divider', 'nd_fantasma', 0),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.notice?.kind, EditorNoticeKind.dropUnknownTarget);
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

    blocTest<EditorCubit, EditorState>(
      'addNode em raiz folha agrupa numa Column em vez de recusar',
      build: () => buildWith(leafRootContent),
      act: (cubit) => cubit.addNode('button', targetId: 'nd_root_text'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root!;
        expect(root.type, 'column');
        expect(root.children, hasLength(2));
        expect(root.children.first.id, 'nd_root_text');
        expect(root.children.last.type, 'button');
        expect(state.notice?.kind, EditorNoticeKind.dropWrapped);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'addNode em raiz single já ocupada agrupa numa Column em vez de recusar',
      build: () => buildWith(occupiedSingleRootContent),
      act: (cubit) => cubit.addNode('button', targetId: 'nd_root_container'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root!;
        expect(root.type, 'column');
        expect(root.children, hasLength(2));
        expect(root.children.first.id, 'nd_root_container');
        expect(root.children.first.child?.id, 'nd_text');
        expect(root.children.last.type, 'button');
        expect(state.notice?.kind, EditorNoticeKind.dropWrapped);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'um único Ctrl+Z desfaz o agrupamento e o encaixe de uma vez (D4)',
      build: () => buildWith(leafRootContent),
      act: (cubit) {
        cubit
          ..addNode('button', targetId: 'nd_root_text')
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, leafRootContent);
        expect(state.canRedo, isTrue);
      },
    );
  });

  group('envolver o nó selecionado (comando explícito)', () {
    blocTest<EditorCubit, EditorState>(
      'wrapSelected troca o nó pelo contêiner no lugar dele e o seleciona',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..wrapSelected('column');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root!;
        expect(root.id, 'nd_root');
        expect(root.children.map((n) => n.id).first, 'nd_banner');
        final wrapper = root.children.last;
        expect(wrapper.type, 'column');
        expect(wrapper.children.single, findNode(content.root!, 'nd_text'));
        expect(state.selectedNodeId, wrapper.id);
        expect(state.saveStatus, SaveStatus.dirty);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'wrapSelected avisa o agrupamento nomeando o contêiner criado',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..wrapSelected('row');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.notice?.kind, EditorNoticeKind.nodeWrapped);
        expect(state.notice?.subjectType, 'row');
        expect(state.document.root!.children.last.type, 'row');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'wrapSelected na raiz troca a raiz e preserva a subárvore inteira',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_root')
          ..wrapSelected('column');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root!;
        expect(root.type, 'column');
        expect(root.id, isNot('nd_root'));
        expect(root.children.single, content.root);
        expect(state.selectedNodeId, root.id);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'envolver a raiz folha devolve o destino ao drop, sem novo agrupamento',
      build: () => buildWith(leafRootContent),
      act: (cubit) {
        cubit
          ..selectNode('nd_root_text')
          ..wrapSelected('column')
          ..addNode('button');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root!;
        expect(root.type, 'column');
        expect(root.children.map((n) => n.type), ['text', 'button']);
        expect(state.notice, isNull);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'wrapSelected sem nó selecionado não emite nada',
      build: buildLoaded,
      act: (cubit) => cubit.wrapSelected('column'),
      expect: () => <EditorState>[],
    );

    blocTest<EditorCubit, EditorState>(
      'wrapSelected em conteúdo vazio não emite nada',
      build: () => buildWith(
        const ContentSpec(
          specVersion: kSpecVersion,
          id: 'ct_vazio',
          name: 'Vazio',
          slug: 'vazio',
        ),
      ),
      act: (cubit) => cubit.wrapSelected('column'),
      expect: () => <EditorState>[],
    );

    blocTest<EditorCubit, EditorState>(
      'um único Ctrl+Z desfaz o envolver e devolve a seleção de antes (D4)',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..wrapSelected('column')
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.selectedNodeId, 'nd_text');
        expect(state.canUndo, isFalse);
        expect(state.canRedo, isTrue);
        expect(state.notice, isNull);
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

  group('histórico — desfazer e refazer', () {
    blocTest<EditorCubit, EditorState>(
      'undo devolve o documento e a seleção de antes da mutação',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..addNode('divider')
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.selectedNodeId, 'nd_text');
        expect(state.canUndo, isFalse);
        expect(state.canRedo, isTrue);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'redo refaz o que o undo desfez',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..addNode('divider')
          ..undo()
          ..redo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children, hasLength(3));
        expect(state.canUndo, isTrue);
        expect(state.canRedo, isFalse);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'undo com pilha vazia não emite nada',
      build: buildLoaded,
      act: (cubit) => cubit.undo(),
      expect: () => <EditorState>[],
    );

    blocTest<EditorCubit, EditorState>(
      'digitar na mesma prop colapsa numa entrada só',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..updateProps('nd_text', {'data': 'O'})
          ..updateProps('nd_text', {'data': 'Ol'})
          ..updateProps('nd_text', {'data': 'Olá'})
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.canUndo, isFalse);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'trocar de prop quebra a sequência do coalescing',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..updateProps('nd_text', {'data': 'Olá'})
          ..updateProps('nd_text', {'fontSize': 20.0})
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final text = findNode(state.document.root!, 'nd_text')!;
        expect(text.properties['data'], 'Olá');
        expect(text.properties.containsKey('fontSize'), isFalse);
        expect(state.canUndo, isTrue);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'mutação nova mata o refazer',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..addNode('divider')
          ..undo()
          ..addNode('button');
      },
      verify: (cubit) {
        expect((cubit.state as EditorReady).canRedo, isFalse);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'o teto de 50 passos descarta os mais antigos',
      build: buildLoaded,
      act: (cubit) {
        for (var i = 0; i < 55; i++) {
          cubit.addNode('divider');
        }
        while ((cubit.state as EditorReady).canUndo) {
          cubit.undo();
        }
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children, hasLength(7));
      },
    );

    blocTest<EditorCubit, EditorState>(
      'a área segura da página também entra no histórico',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..updateSafeAreaProps({'enabled': false})
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.safeArea, isEmpty);
        expect(state.canUndo, isFalse);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'desfazer até o documento do servidor devolve o status salvo',
      build: build,
      setUp: () => when(
        () => loadContent('ct_1'),
      ).thenAnswer((_) async => const Right(loadedContent)),
      act: (cubit) async {
        await cubit.loadContent('ct_1');
        cubit
          ..addNode('divider')
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.saveStatus, SaveStatus.saved);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'abrir outro conteúdo zera as pilhas',
      build: build,
      setUp: () => when(
        () => loadContent('ct_1'),
      ).thenAnswer((_) async => const Right(loadedContent)),
      act: (cubit) async {
        await cubit.loadContent('ct_1');
        cubit.addNode('divider');
        await cubit.loadContent('ct_1');
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.canUndo, isFalse);
        expect(state.canRedo, isFalse);
      },
    );
  });

  group('duplicar, copiar e colar', () {
    const nestedContent = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_nested',
      name: 'Nested',
      slug: 'nested',
      root: SduiNode(
        id: 'nd_root',
        type: 'column',
        children: [
          SduiNode(
            id: 'nd_card',
            type: 'column',
            children: [
              SduiNode(id: 'nd_a', type: 'text'),
              SduiNode(id: 'nd_b', type: 'text'),
              SduiNode(id: 'nd_c', type: 'text'),
            ],
          ),
          SduiNode(id: 'nd_tail', type: 'divider'),
        ],
      ),
    );

    const singleSlotContent = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_single_slot',
      name: 'Single',
      slug: 'single',
      root: SduiNode(
        id: 'nd_root',
        type: 'column',
        children: [
          SduiNode(
            id: 'nd_box',
            type: 'container',
            child: SduiNode(id: 'nd_inner', type: 'text'),
          ),
        ],
      ),
    );

    EditorCubit buildWith(ContentSpec document) =>
        build()..emit(EditorReady(document: document));

    blocTest<EditorCubit, EditorState>(
      'duplicar gera irmão logo abaixo, com ids novos, e seleciona o clone',
      build: () => buildWith(nestedContent),
      act: (cubit) {
        cubit
          ..selectNode('nd_card')
          ..duplicateSelected();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final children = state.document.root!.children;
        expect(children.map((n) => n.type), ['column', 'column', 'divider']);

        final clone = children[1];
        expect(clone.children.map((n) => n.type), ['text', 'text', 'text']);
        expect(
          {clone.id, ...clone.children.map((n) => n.id)},
          isNot(contains(anyOf('nd_card', 'nd_a', 'nd_b', 'nd_c'))),
        );
        expect(state.selectedNodeId, clone.id);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'duplicar a raiz só avisa, não muda o documento',
      build: () => buildWith(nestedContent),
      act: (cubit) {
        cubit
          ..selectNode('nd_root')
          ..duplicateSelected();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, nestedContent);
        expect(state.notice?.kind, EditorNoticeKind.rootNotDuplicable);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'duplicar em slot único sobe para o ancestral e avisa o desvio',
      build: () => buildWith(singleSlotContent),
      act: (cubit) {
        cubit
          ..selectNode('nd_inner')
          ..duplicateSelected();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final children = state.document.root!.children;
        expect(children.map((n) => n.type), ['container', 'text']);
        expect(state.notice?.kind, EditorNoticeKind.dropRedirected);
        expect(state.notice?.subjectType, 'container');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'copiar avisa e não mexe no documento',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..copySelected();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.saveStatus, SaveStatus.saved);
        expect(state.notice?.kind, EditorNoticeKind.nodeCopied);
        expect(state.notice?.subjectType, 'text');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'colar insere o clone no nó selecionado',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..copySelected()
          ..selectNode('nd_root')
          ..paste();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final children = state.document.root!.children;
        expect(children.map((n) => n.type), ['container', 'text', 'text']);
        expect(children.last.id, isNot('nd_text'));
        expect(state.selectedNodeId, children.last.id);
        expect(state.notice, isNull);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'colar sobre folha sobe para o ancestral e avisa o desvio',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_banner')
          ..copySelected()
          ..selectNode('nd_text')
          ..paste();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document.root!.children.map((n) => n.type), [
          'container',
          'text',
          'container',
        ]);
        expect(state.notice?.kind, EditorNoticeKind.dropRedirected);
        expect(state.notice?.subjectType, 'text');
      },
    );

    blocTest<EditorCubit, EditorState>(
      'colar sem nada copiado só avisa',
      build: buildLoaded,
      act: (cubit) => cubit.paste(),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.notice?.kind, EditorNoticeKind.clipboardEmpty);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'colar em conteúdo vazio faz do clone a raiz',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..selectNode('nd_text')
          ..copySelected()
          ..removeNode('nd_root')
          ..paste();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        final root = state.document.root;
        expect(root?.type, 'text');
        expect(root?.id, isNot('nd_text'));
        expect(state.selectedNodeId, root!.id);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'duplicar é uma entrada de histórico, desfeita de uma vez',
      build: () => buildWith(nestedContent),
      act: (cubit) {
        cubit
          ..selectNode('nd_card')
          ..duplicateSelected()
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, nestedContent);
        expect(state.selectedNodeId, 'nd_card');
      },
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

    blocTest<EditorCubit, EditorState>(
      'fitToWindow começa ligado por padrão',
      build: buildLoaded,
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.fitToWindow, isTrue);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'changeZoom (manual) desliga o fitToWindow — P5',
      build: buildLoaded,
      act: (cubit) => cubit.changeZoom(0.7),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.fitToWindow, isFalse);
        expect(state.zoom, 0.7);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'toggleFitToWindow religa depois do zoom manual ter desligado',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..changeZoom(0.7)
          ..toggleFitToWindow();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.fitToWindow, isTrue);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'toggleFitToWindow alterna: ligado → desligado → ligado',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..toggleFitToWindow()
          ..toggleFitToWindow();
      },
      expect: () => [
        isA<EditorReady>().having(
          (s) => s.fitToWindow,
          'fitToWindow',
          isFalse,
        ),
        isA<EditorReady>().having(
          (s) => s.fitToWindow,
          'fitToWindow',
          isTrue,
        ),
      ],
    );
  });

  group('save com checkpoint', () {
    EditorCubit buildDirty() => build()
      ..emit(
        const EditorReady(document: content, saveStatus: SaveStatus.dirty),
      );

    void stubSave() => when(
      () => saveDraft(any(), checkpointNote: any(named: 'checkpointNote')),
    ).thenAnswer((_) async => const Right(unit));

    blocTest<EditorCubit, EditorState>(
      'salvar sem nota não pede marcação nenhuma',
      build: buildDirty,
      setUp: stubSave,
      act: (cubit) => cubit.save(),
      verify: (_) => expect(
        verify(
          () => saveDraft(
            any(),
            checkpointNote: captureAny(named: 'checkpointNote'),
          ),
        ).captured.single,
        isNull,
      ),
    );

    blocTest<EditorCubit, EditorState>(
      'salvar com nota repassa a nota',
      build: buildDirty,
      setUp: stubSave,
      act: (cubit) => cubit.save(checkpointNote: 'antes do banner'),
      verify: (_) => verify(
        () => saveDraft(any(), checkpointNote: 'antes do banner'),
      ).called(1),
    );

    blocTest<EditorCubit, EditorState>(
      'nota só com espaços vira ausente — um ponto sem nota não se distingue '
      'de qualquer outro save no histórico',
      build: buildDirty,
      setUp: stubSave,
      act: (cubit) => cubit.save(checkpointNote: '   '),
      verify: (_) => expect(
        verify(
          () => saveDraft(
            any(),
            checkpointNote: captureAny(named: 'checkpointNote'),
          ),
        ).captured.single,
        isNull,
      ),
    );

    blocTest<EditorCubit, EditorState>(
      'a nota é aparada nas pontas antes de viajar',
      build: buildDirty,
      setUp: stubSave,
      act: (cubit) => cubit.save(checkpointNote: '  ponto  '),
      verify: (_) =>
          verify(() => saveDraft(any(), checkpointNote: 'ponto')).called(1),
    );
  });

  group('publicar', () {
    final published = PublicationState(
      publishedVersion: 3,
      publishedAt: DateTime.utc(2026, 8, 16, 12),
      hasUnpublishedChanges: false,
    );

    EditorCubit buildDirty() => build()
      ..emit(
        const EditorReady(document: content, saveStatus: SaveStatus.dirty),
      );

    blocTest<EditorCubit, EditorState>(
      'sucesso: publishing → published com a publicação do servidor',
      build: buildLoaded,
      setUp: () => when(
        () => publishContent('ct_1', note: any(named: 'note')),
      ).thenAnswer((_) async => Right(published)),
      act: (cubit) => cubit.publish(note: 'primeira subida'),
      expect: () => [
        const EditorReady(
          document: content,
          publishStatus: PublishStatus.publishing,
        ),
        EditorReady(
          document: content,
          publication: published,
          publishStatus: PublishStatus.published,
        ),
      ],
      verify: (_) {
        verify(() => publishContent('ct_1', note: 'primeira subida')).called(1);
        verifyNever(() => saveDraft(any()));
      },
    );

    blocTest<EditorCubit, EditorState>(
      'rascunho sujo: salva antes de publicar, nessa ordem',
      build: buildDirty,
      setUp: () {
        when(() => saveDraft(any())).thenAnswer((_) async => const Right(unit));
        when(
          () => publishContent('ct_1', note: any(named: 'note')),
        ).thenAnswer((_) async => Right(published));
      },
      act: (cubit) => cubit.publish(),
      expect: () => [
        const EditorReady(
          document: content,
          saveStatus: SaveStatus.dirty,
          publishStatus: PublishStatus.publishing,
        ),
        const EditorReady(
          document: content,
          saveStatus: SaveStatus.saving,
          publishStatus: PublishStatus.publishing,
        ),
        const EditorReady(
          document: content,
          publishStatus: PublishStatus.publishing,
        ),
        EditorReady(
          document: content,
          publication: published,
          publishStatus: PublishStatus.published,
        ),
      ],
      verify: (_) => verifyInOrder([
        () => saveDraft(content),
        () => publishContent('ct_1', note: any(named: 'note')),
      ]),
    );

    blocTest<EditorCubit, EditorState>(
      'falha do salvamento aborta antes do publish e avisa o usuário',
      build: buildDirty,
      setUp: () => when(
        () => saveDraft(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.publish(),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.saveStatus, SaveStatus.saveFailed);
        expect(state.publishStatus, PublishStatus.publishFailed);
        expect(state.notice?.kind, EditorNoticeKind.publishFailed);
        verifyNever(() => publishContent(any(), note: any(named: 'note')));
      },
    );

    blocTest<EditorCubit, EditorState>(
      'falha do publish: publishFailed com aviso visível e publicação intacta',
      build: buildLoaded,
      setUp: () => when(
        () => publishContent('ct_1', note: any(named: 'note')),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.publish(),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.publishStatus, PublishStatus.publishFailed);
        expect(state.notice?.kind, EditorNoticeKind.publishFailed);
        expect(
          state.publication,
          const PublicationState(hasUnpublishedChanges: true),
        );
        expect(state.document, content);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'documento com erro de diagnóstico não chega a chamar o publish',
      build: buildLoaded,
      act: (cubit) async {
        cubit.addNode('spacer', targetId: 'nd_banner');
        await cubit.publish();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.canPublish, isFalse);
        expect(state.publishBlockReason, PublishBlockReason.documentErrors);
        expect(state.publishStatus, PublishStatus.idle);
        verifyNever(() => publishContent(any(), note: any(named: 'note')));
      },
    );

    blocTest<EditorCubit, EditorState>(
      'editar um documento publicado e sem pendência marca a top bar como '
      'suja na hora, sem esperar reload (A2)',
      build: () =>
          build()..emit(EditorReady(document: content, publication: published)),
      act: (cubit) => cubit.addNode('divider'),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.publication.hasUnpublishedChanges, isTrue);
        expect(state.publication.publishedVersion, published.publishedVersion);
        expect(state.publication.publishedAt, published.publishedAt);
      },
    );
  });

  group('publishBlockReason', () {
    const contentWithError = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_erro',
      name: 'Erro',
      slug: 'erro',
      root: SduiNode(
        id: 'nd_root',
        type: 'container',
        child: SduiNode(id: 'nd_spacer', type: 'spacer'),
      ),
    );

    test('documento saudável e ocioso pode publicar', () {
      const state = EditorReady(document: content);
      expect(state.publishBlockReason, isNull);
      expect(state.canPublish, isTrue);
    });

    test('diagnóstico de severidade erro bloqueia', () {
      const state = EditorReady(document: contentWithError);
      expect(state.diagnostics.single.severity, DiagnosticSeverity.error);
      expect(state.publishBlockReason, PublishBlockReason.documentErrors);
      expect(state.canPublish, isFalse);
    });

    test('salvando prevalece sobre o erro do documento', () {
      const state = EditorReady(
        document: contentWithError,
        saveStatus: SaveStatus.saving,
      );
      expect(state.publishBlockReason, PublishBlockReason.saving);
    });

    test('publicando prevalece sobre salvando', () {
      const state = EditorReady(
        document: content,
        saveStatus: SaveStatus.saving,
        publishStatus: PublishStatus.publishing,
      );
      expect(state.publishBlockReason, PublishBlockReason.publishing);
    });
  });

  group('despublicar', () {
    final published = PublicationState(
      publishedVersion: 3,
      publishedAt: DateTime.utc(2026, 8, 16, 12),
      hasUnpublishedChanges: false,
    );

    EditorCubit buildPublished() =>
        build()..emit(EditorReady(document: content, publication: published));

    blocTest<EditorCubit, EditorState>(
      'sucesso: sai do ar e o rascunho volta a ter mudanças não publicadas',
      build: buildPublished,
      setUp: () => when(
        () => unpublishContent('ct_1'),
      ).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.unpublish(),
      expect: () => [
        EditorReady(
          document: content,
          publication: published,
          publishStatus: PublishStatus.publishing,
        ),
        const EditorReady(document: content),
      ],
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.publication.isPublished, isFalse);
        expect(state.publication.hasUnpublishedChanges, isTrue);
        expect(state.publishStatus, PublishStatus.idle);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'falha: publishFailed com aviso visível e a publicação continua intacta',
      build: buildPublished,
      setUp: () => when(
        () => unpublishContent('ct_1'),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.unpublish(),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.publishStatus, PublishStatus.publishFailed);
        expect(state.notice?.kind, EditorNoticeKind.unpublishFailed);
        expect(state.publication, published);
        expect(state.publication.isPublished, isTrue);
      },
    );
  });

  group('restaurar versão', () {
    const restored = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: SduiNode(
        id: 'nd_root',
        type: 'column',
        children: [
          SduiNode(id: 'nd_antigo', type: 'text', properties: {'data': 'v2'}),
        ],
      ),
    );

    blocTest<EditorCubit, EditorState>(
      'sucesso: documento restaurado como rascunho sujo e desfazível',
      build: buildLoaded,
      setUp: () => when(
        () => restoreContentVersion('ct_1', 2),
      ).thenAnswer((_) async => const Right(restored)),
      act: (cubit) async {
        expect(await cubit.restoreVersion(2), isTrue);
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, restored);
        expect(state.saveStatus, SaveStatus.dirty);
        expect(state.canUndo, isTrue);
        verify(() => restoreContentVersion('ct_1', 2)).called(1);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'um Ctrl+Z depois de restaurar volta ao rascunho anterior',
      build: buildLoaded,
      setUp: () => when(
        () => restoreContentVersion('ct_1', 2),
      ).thenAnswer((_) async => const Right(restored)),
      act: (cubit) async {
        await cubit.restoreVersion(2);
        cubit.undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.canRedo, isTrue);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'falha: devolve false, avisa e não mexe no documento',
      build: buildLoaded,
      setUp: () => when(
        () => restoreContentVersion('ct_1', 2),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) async {
        expect(await cubit.restoreVersion(2), isFalse);
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.notice?.kind, EditorNoticeKind.restoreFailed);
        expect(state.document, content);
        expect(state.saveStatus, SaveStatus.saved);
        expect(state.canUndo, isFalse);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'restaurar a versão que já está publicada não gera falsa pendência',
      build: () => build()
        ..emit(
          EditorReady(
            document: content,
            publication: PublicationState(
              publishedVersion: 2,
              publishedAt: DateTime.utc(2026, 8, 16, 12),
              hasUnpublishedChanges: false,
            ),
          ),
        ),
      setUp: () => when(
        () => restoreContentVersion('ct_1', 2),
      ).thenAnswer((_) async => const Right(restored)),
      act: (cubit) async {
        expect(await cubit.restoreVersion(2), isTrue);
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, restored);
        expect(state.publication.hasUnpublishedChanges, isFalse);
      },
    );
  });

  group('carregar versão no rascunho (T3, item 50)', () {
    const loaded = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: SduiNode(
        id: 'nd_root',
        type: 'column',
        children: [
          SduiNode(id: 'nd_antigo', type: 'text', properties: {'data': 'v2'}),
        ],
      ),
    );

    blocTest<EditorCubit, EditorState>(
      'aplica o spec já lido, fica sujo e desfazível — sem chamar nenhum '
      'use case de rede',
      build: buildLoaded,
      act: (cubit) => cubit.loadVersionIntoDraft(loaded, version: 2),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, loaded);
        expect(state.saveStatus, SaveStatus.dirty);
        expect(state.canUndo, isTrue);
        verifyZeroInteractions(restoreContentVersion);
        verifyZeroInteractions(saveDraft);
        verifyZeroInteractions(publishContent);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'um Ctrl+Z depois de carregar volta ao rascunho anterior',
      build: buildLoaded,
      act: (cubit) {
        cubit
          ..loadVersionIntoDraft(loaded, version: 2)
          ..undo();
      },
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, content);
        expect(state.canRedo, isTrue);
      },
    );

    blocTest<EditorCubit, EditorState>(
      'carregar a versão que já está publicada não gera falsa pendência',
      build: () => build()
        ..emit(
          EditorReady(
            document: content,
            publication: PublicationState(
              publishedVersion: 2,
              publishedAt: DateTime.utc(2026, 8, 16, 12),
              hasUnpublishedChanges: false,
            ),
          ),
        ),
      act: (cubit) => cubit.loadVersionIntoDraft(loaded, version: 2),
      verify: (cubit) {
        final state = cubit.state as EditorReady;
        expect(state.document, loaded);
        expect(state.publication.hasUnpublishedChanges, isFalse);
      },
    );
  });
}
