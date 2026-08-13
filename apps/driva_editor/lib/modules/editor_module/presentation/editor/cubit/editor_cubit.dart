import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_history_entry.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart'
    show
        ContentSpec,
        DropAccepted,
        DropRefusal,
        DropRefused,
        SduiNode,
        SpecDiagnostic,
        defaultNode;
import 'package:sdui_core/sdui_core.dart' as sdui;

part 'editor_state.dart';

class EditorCubit extends Cubit<EditorState> {
  EditorCubit({
    required this.loadContentUseCase,
    required this.saveDraftUseCase,
    required this.projectId,
  }) : super(const EditorLoading());
  final LoadContentUseCase loadContentUseCase;
  final SaveDraftUseCase saveDraftUseCase;

  /// Projeto ao qual o conteúdo aberto pertence (do `ProjectScope`, injetado
  /// no `pageBuilder`). É o destino do "voltar" do editor — Builder → tela do
  /// projeto (categorias), não a home de projetos.
  final String projectId;

  int _idSequence = 0;
  int _noticeSequence = 0;

  final List<EditorHistoryEntry> _past = [];
  final List<EditorHistoryEntry> _future = [];

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
      (content) => EditorReady(document: content),
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
    }
  }

  /// Encaixe numa posição exata da lista de filhos de [parentId] — as frestas
  /// entre as linhas da árvore, únicas capazes de reordenar para o começo.
  void addNodeAt(String type, String parentId, int index) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;
    if (root == null) return;

    final node = defaultNode(type, id: _nextNodeId(root));
    final newRoot = sdui.attachNode(root, parentId, index, node);
    if (newRoot == null) {
      _emitNotice(current, EditorNoticeKind.dropNoSlot);
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

  void changeZoom(double zoom) {
    final current = state;
    if (current is! EditorReady) return;
    emit(current.copyWith(zoom: zoom.clamp(0.4, 1.5)));
  }

  Future<void> save() async {
    final current = state;
    if (current is! EditorReady) return;
    if (current.saveStatus == SaveStatus.saving) return;
    emit(current.copyWith(saveStatus: SaveStatus.saving));

    final result = await saveDraftUseCase(current.document);
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

  EditorNoticeKind _kindOf(DropRefusal refusal) => switch (refusal) {
    DropRefusal.cycle => EditorNoticeKind.dropCycle,
    DropRefusal.noSlotAvailable => EditorNoticeKind.dropNoSlot,
    DropRefusal.unknownTarget => EditorNoticeKind.dropUnknownTarget,
  };

  EditorNotice _nextNotice(EditorNoticeKind kind, String? subjectType) =>
      EditorNotice(
        kind: kind,
        sequence: ++_noticeSequence,
        subjectType: subjectType,
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
  void _emitDocument(
    EditorReady current,
    ContentSpec document, {
    Object? selectedNodeId = _keepSelection,
    EditorNotice? notice,
    String? coalesceKey,
  }) {
    _pushHistory(current, coalesceKey: coalesceKey);
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
