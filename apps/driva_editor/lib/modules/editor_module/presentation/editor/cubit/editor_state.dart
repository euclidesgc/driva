part of 'editor_cubit.dart';

/// Estado do salvamento, sempre visível na top bar (o I1 não tem auto-save:
/// perder alteração ao fechar é aceito, desde que o "não salvo" esteja claro).
enum SaveStatus { saved, dirty, saving, saveFailed }

sealed class EditorState extends Equatable {
  const EditorState();
  @override
  List<Object?> get props => [];
}

final class EditorLoading extends EditorState {
  const EditorLoading();
}

final class EditorLoadFailure extends EditorState {
  final Failure failure;
  const EditorLoadFailure({required this.failure});
  @override
  List<Object?> get props => [failure];
}

final class EditorReady extends EditorState {
  /// Fonte de verdade única: preview, árvore e inspector derivam daqui.
  final PageSpec document;

  final String? selectedNodeId;
  final DevicePreset device;
  final double zoom;
  final SaveStatus saveStatus;

  const EditorReady({
    required this.document,
    this.selectedNodeId,
    this.device = DevicePreset.smartphone,
    this.zoom = 0.9,
    this.saveStatus = SaveStatus.saved,
  });

  /// Nó selecionado (ou `null`). Derivado — nunca guardado à parte, para não
  /// dessincronizar com o documento.
  SduiNode? get selectedNode => selectedNodeId == null
      ? null
      : sdui.findNode(document.root, selectedNodeId!);

  /// [selectedNodeId] usa função-getter para permitir "setar null"
  /// (armadilha do copyWith com campo nullable, cap. 12 do livro).
  EditorReady copyWith({
    PageSpec? document,
    String? Function()? selectedNodeId,
    DevicePreset? device,
    double? zoom,
    SaveStatus? saveStatus,
  }) {
    return EditorReady(
      document: document ?? this.document,
      selectedNodeId:
          selectedNodeId != null ? selectedNodeId() : this.selectedNodeId,
      device: device ?? this.device,
      zoom: zoom ?? this.zoom,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }

  @override
  List<Object?> get props =>
      [document, selectedNodeId, device, zoom, saveStatus];
}
