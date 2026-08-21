import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_history_entry.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart'
    show
        ContentSpec,
        DiagnosticSeverity,
        DropAccepted,
        DropRefusal,
        DropRefused,
        DropRequiresWrap,
        SduiNode,
        SpecDiagnostic,
        defaultNode;
import 'package:sdui_core/sdui_core.dart' as sdui;

part 'editor_state.dart';

class EditorCubit extends Cubit<EditorState> {
  EditorCubit({
    required this.loadContentUseCase,
    required this.saveDraftUseCase,
    required this.publishContentUseCase,
    required this.unpublishContentUseCase,
    required this.restoreContentVersionUseCase,
    required this.projectId,
  }) : super(const EditorLoading());
  final LoadContentUseCase loadContentUseCase;
  final SaveDraftUseCase saveDraftUseCase;
  final PublishContentUseCase publishContentUseCase;
  final UnpublishContentUseCase unpublishContentUseCase;
  final RestoreContentVersionUseCase restoreContentVersionUseCase;

  /// Projeto ao qual o conteúdo aberto pertence (do `ProjectScope`, injetado
  /// no `pageBuilder`). É o destino do "voltar" do editor — Builder → tela do
  /// projeto (categorias), não a home de projetos.
  final String projectId;

  /// Piso e teto do zoom manual — o clamp de [changeZoom]. O ajuste
  /// automático (D9) não passa por aqui, mas `CanvasToolbar` usa [minZoom]
  /// para saber quando o "−" chegaria a esse piso mesmo com o ajuste ligado
  /// e escala efetiva abaixo dele.
  static const double minZoom = 0.4;

  static const double maxZoom = 1.5;

  int _idSequence = 0;
  int _noticeSequence = 0;

  final List<EditorHistoryEntry> _past = [];
  final List<EditorHistoryEntry> _future = [];

  SduiNode? _clipboard;

  /// Referência ao documento que o servidor tem, para desfazer até ele devolver
  /// o status "salvo" em vez de deixar a top bar mentindo.
  ContentSpec? _lastSavedDocument;

  static const int _maxHistory = 50;

  Future<void> loadContent(String id) async {
    emit(const EditorLoading());
    final result = await loadContentUseCase(id);
    if (isClosed) return;
    _past.clear();
    _future.clear();
    final next = result.fold<EditorState>(
      (failure) => EditorLoadFailure(failure: failure),
      (loaded) =>
          EditorReady(document: loaded.spec, publication: loaded.publication),
    );
    if (next is EditorReady) _lastSavedDocument = next.document;
    emit(next);
  }

  /// Gera um id único dentro do documento atual. Com [root] null (conteúdo
  /// vazio) não há colisão possível — qualquer id serve.
  String _nextNodeId(SduiNode? root) {
    String candidate;
    do {
      candidate =
          'nd_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
          '${_idSequence++}';
    } while (root != null && sdui.findNode(root, candidate) != null);
    return candidate;
  }

  /// Adiciona um primitivo do catálogo sobre [targetId] (sem alvo: o nó
  /// selecionado, ou a raiz). Com o conteúdo vazio (`root == null`), o primeiro
  /// nó adicionado **vira a raiz** e fica selecionado — de qualquer tipo.
  ///
  /// Alvo que não recebe filhos não cancela o gesto: o kernel encaixa no
  /// primeiro ancestral que recebe e a barra de status conta o desvio.
  void addNode(String type, {String? targetId}) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;

    if (root == null) {
      final rootNode = defaultNode(type, id: _nextNodeId(null));
      _emitRoot(current, rootNode, selectedNodeId: rootNode.id);
      return;
    }

    final wanted = targetId ?? current.selectedNodeId ?? root.id;
    final target = sdui.findNode(root, wanted) ?? root;

    switch (sdui.resolveDrop(root, target.id)) {
      case DropRefused(:final refusal):
        _emitNotice(current, _kindOf(refusal), subjectType: target.type);
      case DropAccepted(:final parentId, :final index, :final redirected):
        final node = defaultNode(type, id: _nextNodeId(root));
        final newRoot = sdui.attachNode(root, parentId, index, node);
        if (newRoot == null) return;
        _emitRoot(
          current,
          newRoot,
          selectedNodeId: node.id,
          notice: redirected
              ? _nextNotice(EditorNoticeKind.dropRedirected, target.type)
              : null,
        );
      case DropRequiresWrap(:final wrapTargetId, :final wrapperType):
        final wrap = _wrap(root, wrapTargetId, wrapperType);
        if (wrap == null) return;
        final node = defaultNode(type, id: _nextNodeId(wrap.root));
        final newRoot = sdui.attachNode(
          wrap.root,
          wrap.wrapperId,
          _appendIndex(wrap.root, wrap.wrapperId),
          node,
        );
        if (newRoot == null) return;
        _emitRoot(
          current,
          newRoot,
          selectedNodeId: node.id,
          notice: _nextNotice(
            EditorNoticeKind.dropWrapped,
            target.type,
            wrapperType: wrapperType,
          ),
        );
    }
  }

  /// Move um nó existente para cima de [targetId] — a mesma resolução do
  /// [addNode], para árvore e canvas se comportarem igual.
  void moveNode(String nodeId, String targetId) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null || nodeId == targetId) return;
    if (nodeId == root.id) {
      _emitNotice(current, EditorNoticeKind.rootNotMovable);
      return;
    }
    final target = sdui.findNode(root, targetId);
    if (target == null) {
      _emitNotice(current, EditorNoticeKind.dropUnknownTarget);
      return;
    }

    switch (sdui.resolveDrop(root, targetId, movingNodeId: nodeId)) {
      case DropRefused(:final refusal):
        _emitNotice(current, _kindOf(refusal), subjectType: target.type);
      case DropAccepted(:final parentId, :final index, :final redirected):
        final newRoot = sdui.moveNode(root, nodeId, parentId, index);
        if (newRoot == root) return;
        _emitRoot(
          current,
          newRoot,
          notice: redirected
              ? _nextNotice(EditorNoticeKind.dropRedirected, target.type)
              : null,
        );
      case DropRequiresWrap(:final wrapTargetId, :final wrapperType):
        final wrap = _wrap(root, wrapTargetId, wrapperType);
        if (wrap == null) return;
        final newRoot = sdui.moveNode(
          wrap.root,
          nodeId,
          wrap.wrapperId,
          _appendIndex(wrap.root, wrap.wrapperId),
        );
        if (newRoot == wrap.root) return;
        _emitRoot(
          current,
          newRoot,
          notice: _nextNotice(
            EditorNoticeKind.dropWrapped,
            target.type,
            wrapperType: wrapperType,
          ),
        );
    }
  }

  /// Encaixe numa posição exata da lista de filhos de [parentId] — as frestas
  /// entre as linhas da árvore, únicas capazes de reordenar para o começo.
  ///
  /// `attachNode` nulo por [parentId] inexistente é recusa de verdade; nulo
  /// por pai que não aceita lista converge para [addNode], que resolve o
  /// mesmo gesto (redirect ou wrap) que os outros quatro pontos de drop.
  void addNodeAt(String type, String parentId, int index) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null) return;

    if (sdui.findNode(root, parentId) == null) {
      _emitNotice(current, EditorNoticeKind.dropUnknownTarget);
      return;
    }

    final node = defaultNode(type, id: _nextNodeId(root));
    final newRoot = sdui.attachNode(root, parentId, index, node);
    if (newRoot == null) {
      addNode(type, targetId: parentId);
      return;
    }
    _emitRoot(current, newRoot, selectedNodeId: node.id);
  }

  void moveNodeAt(String nodeId, String parentId, int index) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null) return;
    if (nodeId == root.id) {
      _emitNotice(current, EditorNoticeKind.rootNotMovable);
      return;
    }
    final moving = sdui.findNode(root, nodeId);
    if (moving == null) {
      _emitNotice(current, EditorNoticeKind.dropUnknownTarget);
      return;
    }
    if (sdui.findNode(moving, parentId) != null) {
      _emitNotice(current, EditorNoticeKind.dropCycle);
      return;
    }

    final newRoot = sdui.moveNode(root, nodeId, parentId, index);
    if (newRoot == root) return;
    _emitRoot(current, newRoot);
  }

  void removeNode(String id) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null) return;
    // Excluir a raiz esvazia o conteúdo (volta ao estado-vazio): não é fixa.
    if (id == root.id) {
      _emitRoot(current, null, selectedNodeId: null);
      return;
    }
    final newRoot = sdui.removeNode(root, id);
    final selection = current.selectedNodeId == id
        ? null
        : current.selectedNodeId;
    _emitRoot(current, newRoot, selectedNodeId: selection);
  }

  /// Área de transferência **interna** do editor: um nó vivo, não texto do SO.
  /// Colar entre abas exigiria serializar, revalidar pelo kernel e tratar spec
  /// de outra versão — outra fatia. Não é limpa por [loadContent] de propósito:
  /// copiar num conteúdo e colar em outro, na mesma sessão, é desejável.
  void copySelected() {
    final current = state;
    if (current is! EditorReady) return;
    final node = current.selectedNode;
    if (node == null) return;
    _clipboard = node;
    _emitNotice(
      current,
      EditorNoticeKind.nodeCopied,
      subjectType: node.type,
    );
  }

  void duplicateSelected() {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    final node = current.selectedNode;
    if (root == null || node == null) return;
    if (node.id == root.id) {
      _emitNotice(current, EditorNoticeKind.rootNotDuplicable);
      return;
    }
    final parent = sdui.findParent(root, node.id);
    if (parent == null) return;

    final position = parent.children.indexWhere((c) => c.id == node.id);
    if (position >= 0) {
      _emitClone(current, root, node, parent.id, position + 1);
      return;
    }

    // O original ocupa um slot único: não há lugar ao lado dele. Sobe para o
    // primeiro ancestral que recebe, exatamente como faz o arraste.
    switch (sdui.resolveDrop(root, parent.id)) {
      case DropRefused(:final refusal):
        _emitNotice(current, _kindOf(refusal), subjectType: parent.type);
      case DropAccepted(:final parentId, :final index, :final redirected):
        _emitClone(
          current,
          root,
          node,
          parentId,
          index,
          notice: redirected
              ? _nextNotice(EditorNoticeKind.dropRedirected, parent.type)
              : null,
        );
      case DropRequiresWrap(:final wrapTargetId, :final wrapperType):
        final wrap = _wrap(root, wrapTargetId, wrapperType);
        if (wrap == null) return;
        _emitClone(
          current,
          wrap.root,
          node,
          wrap.wrapperId,
          _appendIndex(wrap.root, wrap.wrapperId),
          notice: _nextNotice(
            EditorNoticeKind.dropWrapped,
            parent.type,
            wrapperType: wrapperType,
          ),
        );
    }
  }

  /// Colar é um drop no nó selecionado — mesma regra de encaixe do arraste,
  /// inclusive o desvio para o ancestral quando o alvo não recebe filhos.
  void paste() {
    final current = state;
    if (current is! EditorReady) return;
    final source = _clipboard;
    if (source == null) {
      _emitNotice(current, EditorNoticeKind.clipboardEmpty);
      return;
    }
    final root = current.document.root;
    if (root == null) {
      final clone = sdui.cloneWithNewIds(source, () => _nextNodeId(null));
      _emitRoot(current, clone, selectedNodeId: clone.id);
      return;
    }

    final wanted = current.selectedNodeId ?? root.id;
    final target = sdui.findNode(root, wanted) ?? root;
    switch (sdui.resolveDrop(root, target.id)) {
      case DropRefused(:final refusal):
        _emitNotice(current, _kindOf(refusal), subjectType: target.type);
      case DropAccepted(:final parentId, :final index, :final redirected):
        _emitClone(
          current,
          root,
          source,
          parentId,
          index,
          notice: redirected
              ? _nextNotice(EditorNoticeKind.dropRedirected, target.type)
              : null,
        );
      case DropRequiresWrap(:final wrapTargetId, :final wrapperType):
        final wrap = _wrap(root, wrapTargetId, wrapperType);
        if (wrap == null) return;
        _emitClone(
          current,
          wrap.root,
          source,
          wrap.wrapperId,
          _appendIndex(wrap.root, wrap.wrapperId),
          notice: _nextNotice(
            EditorNoticeKind.dropWrapped,
            target.type,
            wrapperType: wrapperType,
          ),
        );
    }
  }

  void _emitClone(
    EditorReady current,
    SduiNode root,
    SduiNode source,
    String parentId,
    int index, {
    EditorNotice? notice,
  }) {
    final clone = sdui.cloneWithNewIds(source, () => _nextNodeId(root));
    final newRoot = sdui.attachNode(root, parentId, index, clone);
    if (newRoot == null) {
      _emitNotice(current, EditorNoticeKind.dropUnknownTarget);
      return;
    }
    _emitRoot(current, newRoot, selectedNodeId: clone.id, notice: notice);
  }

  /// Comando explícito de envolver (D6, item 38). Uma chamada de
  /// [sdui.wrapNode] + uma de [_emitRoot]: uma única entrada de undo (D4).
  void wrapSelected(String wrapperType) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    final nodeId = current.selectedNodeId;
    if (root == null || nodeId == null) return;

    final newId = _nextNodeId(root);
    final newRoot = sdui.wrapNode(root, nodeId, wrapperType, newId: newId);
    assert(
      newRoot != null,
      'wrapNode($wrapperType) devolveu null: $wrapperType não aceita '
      'múltiplos filhos no catálogo — só column/row chegam aqui pela UI.',
    );
    if (newRoot == null) return;
    _emitRoot(
      current,
      newRoot,
      selectedNodeId: newId,
      notice: _nextNotice(EditorNoticeKind.nodeWrapped, wrapperType),
    );
  }

  void removeSelected() {
    final current = state;
    if (current is! EditorReady) return;
    final selected = current.selectedNodeId;
    if (selected != null) removeNode(selected);
  }

  /// Merge nas props do nó; valor `null` remove a chave (volta ao default).
  void updateProps(String id, Map<String, dynamic> patch) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null) return;
    _emitRoot(
      current,
      sdui.updateNodeProps(root, id, patch),
      coalesceKey: 'props:$id:${patch.keys.join(",")}',
    );
  }

  /// Copia uma propriedade da candidata comparada (T5b, item 50) para o
  /// nó do rascunho; `value` nulo é o caso "a versão não tem essa
  /// propriedade" e remove a chave, igual a [updateProps]. Não passa
  /// `coalesceKey`: fundir com uma digitação anterior na mesma propriedade
  /// faria um único `Ctrl+Z` desfazer as duas de uma vez.
  void copyPropertyFromVersion(
    String nodeId,
    String propertyKey,
    Object? value,
  ) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null) return;
    if (sdui.findNode(root, nodeId) == null) return;
    _emitRoot(
      current,
      sdui.updateNodeProps(root, nodeId, {propertyKey: value}),
    );
  }

  /// Área segura da página: chrome do conteúdo, fora da árvore de nós.
  void updateSafeAreaProps(Map<String, dynamic> patch) {
    final current = state;
    if (current is! EditorReady) return;
    final merged = {...current.document.safeArea, ...patch}
      ..removeWhere((_, value) => value == null);
    _emitDocument(
      current,
      current.document.copyWith(safeArea: merged),
      coalesceKey: 'safeArea:${patch.keys.join(",")}',
    );
  }

  void selectNode(String? id) {
    final current = state;
    if (current is! EditorReady) return;
    emit(current.copyWith(selectedNodeId: () => id));
  }

  void changeDevice(DevicePreset device) {
    final current = state;
    if (current is! EditorReady) return;
    emit(current.copyWith(device: device));
  }

  /// Zoom manual vence o ajuste automático (P5): desliga
  /// [EditorReady.fitToWindow].
  void changeZoom(double zoom) {
    final current = state;
    if (current is! EditorReady) return;
    emit(
      current.copyWith(zoom: zoom.clamp(minZoom, maxZoom), fitToWindow: false),
    );
  }

  void toggleFitToWindow() {
    final current = state;
    if (current is! EditorReady) return;
    emit(current.copyWith(fitToWindow: !current.fitToWindow));
  }

  /// [checkpointNote] marca um ponto no histórico junto do save — o "commit"
  /// do editor. Salvar continua não publicando: o ponto marcado aqui nunca vai
  /// ao ar, e só publicar cria versão. Nota em branco é tratada como ausente:
  /// um ponto sem nota é indistinguível de qualquer outro save.
  Future<void> save({String? checkpointNote}) async {
    final current = state;
    if (current is! EditorReady) return;
    if (current.saveStatus == SaveStatus.saving) return;
    emit(current.copyWith(saveStatus: SaveStatus.saving));

    final note = checkpointNote?.trim();
    final result = await saveDraftUseCase(
      current.document,
      checkpointNote: note == null || note.isEmpty ? null : note,
    );
    if (isClosed) return;
    final latest = state;
    if (latest is! EditorReady) return;
    if (result.isLeft()) {
      emit(latest.copyWith(saveStatus: SaveStatus.saveFailed));
      return;
    }
    _lastSavedDocument = current.document;
    emit(latest.copyWith(saveStatus: _statusFor(latest.document)));
  }

  /// Guarda [EditorReady.canPublish]; se o rascunho estiver sujo, salva
  /// primeiro — publicar o que está na tela e não no servidor seria mentira.
  /// Falha do salvamento aborta sem chamar o publish.
  Future<void> publish({String? note}) async {
    final current = state;
    if (current is! EditorReady || !current.canPublish) return;
    emit(current.copyWith(publishStatus: PublishStatus.publishing));

    if (current.saveStatus == SaveStatus.dirty) {
      await save();
      if (isClosed) return;
    }

    final beforePublish = state;
    if (beforePublish is! EditorReady ||
        beforePublish.saveStatus != SaveStatus.saved) {
      if (beforePublish is EditorReady) {
        emit(
          beforePublish.copyWith(
            publishStatus: PublishStatus.publishFailed,
            notice: () => _nextNotice(EditorNoticeKind.publishFailed, null),
          ),
        );
      }
      return;
    }

    final result = await publishContentUseCase(
      beforePublish.document.id,
      note: note,
    );
    if (isClosed) return;
    final latest = state;
    if (latest is! EditorReady) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(
          publishStatus: PublishStatus.publishFailed,
          notice: () => _nextNotice(EditorNoticeKind.publishFailed, null),
        ),
      ),
      (publication) => emit(
        latest.copyWith(
          publication: publication,
          publishStatus: PublishStatus.published,
        ),
      ),
    );
  }

  Future<void> unpublish() async {
    final current = state;
    if (current is! EditorReady) return;
    emit(current.copyWith(publishStatus: PublishStatus.publishing));

    final result = await unpublishContentUseCase(current.document.id);
    if (isClosed) return;
    final latest = state;
    if (latest is! EditorReady) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(
          publishStatus: PublishStatus.publishFailed,
          notice: () => _nextNotice(EditorNoticeKind.unpublishFailed, null),
        ),
      ),
      (_) => emit(
        latest.copyWith(
          publication: PublicationState(
            hasUnpublishedChanges: true,
            latestVersion: latest.publication.latestVersion,
          ),
          publishStatus: PublishStatus.idle,
        ),
      ),
    );
  }

  /// Restaura o spec da versão para o **rascunho** (D4 do plano do item 24)
  /// — o que está no ar não muda até um publish explícito. Passa por
  /// [_emitDocument] para virar uma entrada de histórico desfazível (item 23).
  /// Devolve se restaurou: o diálogo de histórico só fecha em sucesso — em
  /// falha, o aviso aparece na barra de status e a lista continua aberta.
  Future<bool> restoreVersion(int version) async {
    final current = state;
    if (current is! EditorReady) return false;

    final result = await restoreContentVersionUseCase(
      current.document.id,
      version,
    );
    if (isClosed) return false;
    final latest = state;
    if (latest is! EditorReady) return false;

    return result.fold(
      (failure) {
        _emitNotice(latest, EditorNoticeKind.restoreFailed);
        return false;
      },
      (spec) {
        final restoresPublishedVersion =
            version == latest.publication.publishedVersion;
        _emitDocument(
          latest,
          spec,
          markUnpublished: !restoresPublishedVersion,
        );
        return true;
      },
    );
  }

  /// Aplica em memória o spec de uma versão já lida por GET (T3, item 50):
  /// nunca chama o endpoint remoto `restore` — só o próximo [save] persiste.
  /// Passa pelo mesmo [_emitDocument] de [restoreVersion], então vira uma
  /// entrada de undo e marca o rascunho sujo, salvo quando a versão já é a
  /// publicada.
  void loadVersionIntoDraft(ContentSpec spec, {required int version}) {
    final current = state;
    if (current is! EditorReady) return;
    final loadsPublishedVersion =
        version == current.publication.publishedVersion;
    _emitDocument(current, spec, markUnpublished: !loadsPublishedVersion);
  }

  /// A volta à versão publicada mora no cubit do modo de comparação, que
  /// não tem canal próprio para a barra de status — a falha dele aparece
  /// aqui, no mesmo lugar das falhas de publicar/restaurar.
  void notifyLoadPublishedFailed() {
    final current = state;
    if (current is! EditorReady) return;
    _emitNotice(current, EditorNoticeKind.loadPublishedFailed);
  }

  /// Aplica o resultado de `copyComparableNodeProperties` (motor puro do
  /// `sdui_core`, T5 do item 50): [updatedDocument] já é o rascunho com só
  /// as `properties` do nó copiado da candidata. Mesmo funil de
  /// [_emitDocument] de qualquer edição comum — vira entrada de undo, marca
  /// sujo, nunca persiste ou toca `restore` sozinho.
  void applyComparedNodeProperties(ContentSpec updatedDocument) {
    final current = state;
    if (current is! EditorReady) return;
    _emitDocument(current, updatedDocument);
  }

  EditorNoticeKind _kindOf(DropRefusal refusal) => switch (refusal) {
    DropRefusal.cycle => EditorNoticeKind.dropCycle,
    DropRefusal.unknownTarget => EditorNoticeKind.dropUnknownTarget,
  };

  /// Compõe o [sdui.wrapNode] (D3) com o encaixe que motivou o gesto, em
  /// memória — quem chama emite **uma** vez só, para que o `Ctrl+Z` desfaça
  /// o agrupamento inteiro numa tacada (D4).
  ({SduiNode root, String wrapperId})? _wrap(
    SduiNode root,
    String wrapTargetId,
    String wrapperType,
  ) {
    final wrapperId = _nextNodeId(root);
    final wrapped = sdui.wrapNode(
      root,
      wrapTargetId,
      wrapperType,
      newId: wrapperId,
    );
    if (wrapped == null) return null;
    return (root: wrapped, wrapperId: wrapperId);
  }

  int _appendIndex(SduiNode root, String parentId) =>
      sdui.findNode(root, parentId)?.children.length ?? 0;

  EditorNotice _nextNotice(
    EditorNoticeKind kind,
    String? subjectType, {
    String? wrapperType,
  }) => EditorNotice(
    kind: kind,
    sequence: ++_noticeSequence,
    subjectType: subjectType,
    wrapperType: wrapperType,
  );

  void _emitNotice(
    EditorReady current,
    EditorNoticeKind kind, {
    String? subjectType,
  }) {
    emit(current.copyWith(notice: () => _nextNotice(kind, subjectType)));
  }

  void _emitRoot(
    EditorReady current,
    SduiNode? newRoot, {
    Object? selectedNodeId = _keepSelection,
    EditorNotice? notice,
    String? coalesceKey,
  }) {
    _emitDocument(
      current,
      current.document.copyWith(root: () => newRoot),
      selectedNodeId: selectedNodeId,
      notice: notice,
      coalesceKey: coalesceKey,
    );
  }

  /// Funil único de toda mutação do documento — é aqui que o passo entra no
  /// histórico. Um `emit` que troque `document` por fora abre buraco silencioso
  /// no desfazer.
  ///
  /// Também é aqui que a top bar deixa de mentir "Publicado (vN)" depois de
  /// uma
  /// edição: se [EditorReady.publication] ainda estava "publicado e sem
  /// pendência", a mutação marca `hasUnpublishedChanges`. O valor definitivo
  /// (versão/data) só volta do servidor no próximo [publish]/[loadContent];
  /// aqui é só o booleano local. [markUnpublished] existe para o único
  /// chamador que restaura a versão já publicada — aí a mutação não deixa o
  /// rascunho realmente pendente.
  void _emitDocument(
    EditorReady current,
    ContentSpec document, {
    Object? selectedNodeId = _keepSelection,
    EditorNotice? notice,
    String? coalesceKey,
    bool markUnpublished = true,
  }) {
    _pushHistory(current, coalesceKey: coalesceKey);
    final publication =
        markUnpublished && !current.publication.hasUnpublishedChanges
        ? current.publication.copyWith(hasUnpublishedChanges: true)
        : current.publication;
    emit(
      current.copyWith(
        document: document,
        saveStatus: SaveStatus.dirty,
        selectedNodeId: identical(selectedNodeId, _keepSelection)
            ? null
            : () => selectedNodeId as String?,
        notice: () => notice,
        canUndo: _past.isNotEmpty,
        canRedo: _future.isNotEmpty,
        publication: publication,
      ),
    );
  }

  void _pushHistory(EditorReady current, {String? coalesceKey}) {
    _future.clear();
    final continuesTopEntry =
        coalesceKey != null &&
        _past.isNotEmpty &&
        _past.last.coalesceKey == coalesceKey;
    if (continuesTopEntry) return;

    _past.add(
      EditorHistoryEntry(
        document: current.document,
        selectedNodeId: current.selectedNodeId,
        coalesceKey: coalesceKey,
      ),
    );
    if (_past.length > _maxHistory) _past.removeAt(0);
  }

  void undo() {
    final current = state;
    if (current is! EditorReady || _past.isEmpty) return;
    final entry = _past.removeLast();
    _future.add(_entryFrom(current, entry.coalesceKey));
    emit(_restored(current, entry));
  }

  void redo() {
    final current = state;
    if (current is! EditorReady || _future.isEmpty) return;
    final entry = _future.removeLast();
    _past.add(_entryFrom(current, entry.coalesceKey));
    emit(_restored(current, entry));
  }

  EditorHistoryEntry _entryFrom(EditorReady current, String? coalesceKey) =>
      EditorHistoryEntry(
        document: current.document,
        selectedNodeId: current.selectedNodeId,
        coalesceKey: coalesceKey,
      );

  EditorReady _restored(EditorReady current, EditorHistoryEntry entry) =>
      current.copyWith(
        document: entry.document,
        selectedNodeId: () => entry.selectedNodeId,
        saveStatus: _statusFor(entry.document),
        notice: () => null,
        canUndo: _past.isNotEmpty,
        canRedo: _future.isNotEmpty,
      );

  SaveStatus _statusFor(ContentSpec document) =>
      document == _lastSavedDocument ? SaveStatus.saved : SaveStatus.dirty;

  static const Object _keepSelection = Object();
}
