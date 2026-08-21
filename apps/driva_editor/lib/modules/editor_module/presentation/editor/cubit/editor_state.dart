part of 'editor_cubit.dart';

/// Estado do salvamento, sempre visível na top bar (o I1 não tem auto-save:
/// perder alteração ao fechar é aceito, desde que o "não salvo" esteja claro).
enum SaveStatus { saved, dirty, saving, saveFailed }

/// Estado da ação de publicar/despublicar em si (transiente) — distinto de
/// [PublicationState], que é o retrato persistente do que está no ar.
enum PublishStatus { idle, publishing, published, publishFailed }

/// Motivo de [EditorReady.canPublish] estar falso — guia o tooltip do botão
/// Publish: o motivo mostrado tem que ser verdadeiro (acessibilidade), não
/// sempre "corrija os erros" mesmo quando só está ocupado salvando/publicando.
enum PublishBlockReason {
  comparingVersions,
  saving,
  publishing,
  documentErrors,
}

sealed class EditorState extends Equatable {
  const EditorState();
  @override
  List<Object?> get props => [];
}

final class EditorLoading extends EditorState {
  const EditorLoading();
}

final class EditorLoadFailure extends EditorState {
  const EditorLoadFailure({required this.failure});
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

final class EditorReady extends EditorState {
  const EditorReady({
    required this.document,
    this.selectedNodeId,
    this.device = DevicePreset.smartphone,
    this.zoom = 0.9,
    this.fitToWindow = true,
    this.saveStatus = SaveStatus.saved,
    this.notice,
    this.canUndo = false,
    this.canRedo = false,
    this.publication = const PublicationState(hasUnpublishedChanges: true),
    this.publishStatus = PublishStatus.idle,
    this.isReadOnly = false,
  });

  /// Fonte de verdade única: preview, árvore e inspector derivam daqui.
  final ContentSpec document;

  final String? selectedNodeId;
  final DevicePreset device;
  final double zoom;

  /// Escala calculada para caber a moldura na janela (D9) prevalece sobre
  /// [zoom] enquanto ligado; um clique manual no zoom desliga (P5).
  final bool fitToWindow;
  final SaveStatus saveStatus;

  /// Recado do último arraste que não terminou onde o usuário apontou. Vive
  /// até a próxima mudança no documento.
  final EditorNotice? notice;

  /// Capacidade, não conteúdo: as pilhas do histórico moram no cubit. Guardar
  /// as listas aqui faria o `props` do Equatable comparar até 50 documentos a
  /// cada emit.
  final bool canUndo;
  final bool canRedo;

  /// Retrato persistente do que está no ar — vem do servidor, não do cubit.
  final PublicationState publication;

  /// Estado transiente da ação de publicar/despublicar em si.
  final PublishStatus publishStatus;

  /// Congela o rascunho: enquanto ligado, nenhuma operação que muda o
  /// documento ou o servidor passa pelo cubit — seleção, zoom e dispositivo
  /// continuam. Ligado pelo modo de comparação de versões, que compara o
  /// rascunho com uma versão do histórico e não pode ver o alvo se mexendo
  /// por baixo; carregar a versão inteira é a única escrita que atravessa,
  /// porque é a saída do modo.
  final bool isReadOnly;

  /// Bloqueia publicar enquanto salva, enquanto publica, ou com diagnóstico
  /// de severidade erro no documento — hoje só `expanded`/`spacer` fora de
  /// flex (`sdui.diagnoseTree`); aviso não bloqueia. `null` quando pode
  /// publicar; a ordem decide qual motivo prevalece se mais de um for
  /// verdade.
  PublishBlockReason? get publishBlockReason {
    if (isReadOnly) return PublishBlockReason.comparingVersions;
    if (publishStatus == PublishStatus.publishing) {
      return PublishBlockReason.publishing;
    }
    if (saveStatus == SaveStatus.saving) return PublishBlockReason.saving;
    if (diagnostics.any((d) => d.severity == DiagnosticSeverity.error)) {
      return PublishBlockReason.documentErrors;
    }
    return null;
  }

  bool get canPublish => publishBlockReason == null;

  /// Nó selecionado (ou `null`). Derivado — nunca guardado à parte, para não
  /// dessincronizar com o documento.
  SduiNode? get selectedNode {
    final root = document.root;
    if (selectedNodeId == null || root == null) return null;
    return sdui.findNode(root, selectedNodeId!);
  }

  /// Problemas estruturais do documento, recalculados a partir dele — mover um
  /// widget para um lugar que o renderer ignora é permitido, e aparece aqui.
  List<SpecDiagnostic> get diagnostics => sdui.diagnoseTree(document.root);

  /// [selectedNodeId] e [notice] usam função-getter para permitir "setar null"
  /// (armadilha do copyWith com campo nullable, cap. 12 do livro).
  EditorReady copyWith({
    ContentSpec? document,
    String? Function()? selectedNodeId,
    DevicePreset? device,
    double? zoom,
    bool? fitToWindow,
    SaveStatus? saveStatus,
    EditorNotice? Function()? notice,
    bool? canUndo,
    bool? canRedo,
    PublicationState? publication,
    PublishStatus? publishStatus,
    bool? isReadOnly,
  }) {
    return EditorReady(
      document: document ?? this.document,
      selectedNodeId: selectedNodeId != null
          ? selectedNodeId()
          : this.selectedNodeId,
      device: device ?? this.device,
      zoom: zoom ?? this.zoom,
      fitToWindow: fitToWindow ?? this.fitToWindow,
      saveStatus: saveStatus ?? this.saveStatus,
      notice: notice != null ? notice() : this.notice,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      publication: publication ?? this.publication,
      publishStatus: publishStatus ?? this.publishStatus,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }

  @override
  List<Object?> get props => [
    document,
    selectedNodeId,
    device,
    zoom,
    fitToWindow,
    saveStatus,
    notice,
    canUndo,
    canRedo,
    publication,
    publishStatus,
    isReadOnly,
  ];
}
