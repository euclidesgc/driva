/// Payloads de drag-and-drop do editor. Dois gestos, um protocolo:
/// arrastar da paleta (cria nó novo) e arrastar na árvore (move nó).
sealed class DragPayload {
  const DragPayload();
}

final class PaletteDragPayload extends DragPayload {
  const PaletteDragPayload(this.type);

  /// Tipo do primitivo do catálogo.
  final String type;
}

final class NodeDragPayload extends DragPayload {
  const NodeDragPayload(this.nodeId);

  final String nodeId;
}
