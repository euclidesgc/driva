import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart' as sdui;
import 'package:sdui_core/sdui_core.dart'
    show PageSpec, SduiNode, SlotKind, defaultNode, descriptorFor;

import '../../../../../core/error/error.dart';
import '../../../domain/use_cases/use_cases.dart';
import '../device_preset.dart';

part 'editor_state.dart';

class EditorCubit extends Cubit<EditorState> {
  final LoadPageUseCase loadPageUseCase;
  final SaveDraftUseCase saveDraftUseCase;

  EditorCubit({required this.loadPageUseCase, required this.saveDraftUseCase})
    : super(const EditorLoading());

  int _idSequence = 0;

  Future<void> loadPage(String id) async {
    emit(const EditorLoading());
    final result = await loadPageUseCase(id);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => EditorLoadFailure(failure: failure),
        (page) => EditorReady(document: page),
      ),
    );
  }

  /// Gera um id único dentro do documento atual.
  String _nextNodeId(SduiNode root) {
    String candidate;
    do {
      candidate =
          'nd_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
          '${_idSequence++}';
    } while (sdui.findNode(root, candidate) != null);
    return candidate;
  }

  /// Adiciona um primitivo do catálogo. Sem [parentId], resolve o destino:
  /// nó selecionado que aceita filhos, ou a raiz.
  void addNode(String type, {String? parentId, int? index}) {
    final current = state;
    if (current is! EditorReady) return;
    final root = current.document.root;

    final node = defaultNode(type, id: _nextNodeId(root));
    final targetId = parentId ?? current.selectedNodeId ?? root.id;
    final target = sdui.findNode(root, targetId) ?? root;
    final slot = descriptorFor(target.type)?.slot ?? SlotKind.none;

    final SduiNode newRoot;
    switch (slot) {
      case SlotKind.multi:
        newRoot = sdui.insertChild(
          root,
          target.id,
          index ?? target.children.length,
          node,
        );
      case SlotKind.single when target.child == null:
        newRoot = sdui.setChild(root, target.id, node);
      // Alvo é folha (ou single ocupado): entra na raiz, depois do alvo se
      // ele for bloco de topo.
      case SlotKind.single || SlotKind.none:
        final topIndex = root.children.indexWhere(
          (child) => child.id == target.id,
        );
        newRoot = sdui.insertChild(
          root,
          root.id,
          index ?? (topIndex >= 0 ? topIndex + 1 : root.children.length),
          node,
        );
    }

    _emitDocument(current, newRoot, selectedNodeId: node.id);
  }

  /// Move um nó existente para `children` de [newParentId] em [index].
  /// Movimentos inválidos (ciclo, destino inexistente) são ignorados pelo
  /// kernel — o documento simplesmente não muda.
  void moveNode(String id, String newParentId, int index) {
    final current = state;
    if (current is! EditorReady) return;
    final newRoot = sdui.moveNode(
      current.document.root,
      id,
      newParentId,
      index,
    );
    if (identical(newRoot, current.document.root)) return;
    _emitDocument(current, newRoot);
  }

  void removeNode(String id) {
    final current = state;
    if (current is! EditorReady) return;
    if (id == current.document.root.id) return;
    final newRoot = sdui.removeNode(current.document.root, id);
    final selection = current.selectedNodeId == id
        ? null
        : current.selectedNodeId;
    _emitDocument(current, newRoot, selectedNodeId: selection);
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
    _emitDocument(
      current,
      sdui.updateNodeProps(current.document.root, id, patch),
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
    emit(
      latest.copyWith(
        saveStatus: result.isRight() ? SaveStatus.saved : SaveStatus.saveFailed,
      ),
    );
  }

  void _emitDocument(
    EditorReady current,
    SduiNode newRoot, {
    Object? selectedNodeId = _keepSelection,
  }) {
    emit(
      current.copyWith(
        document: current.document.copyWith(root: newRoot),
        saveStatus: SaveStatus.dirty,
        selectedNodeId: identical(selectedNodeId, _keepSelection)
            ? null
            : () => selectedNodeId as String?,
      ),
    );
  }

  static const Object _keepSelection = Object();
}
