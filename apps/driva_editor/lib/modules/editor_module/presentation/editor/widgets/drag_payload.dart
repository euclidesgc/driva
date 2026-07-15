sealed class DragPayload {
  const DragPayload();
}

final class PaletteDragPayload extends DragPayload {
  const PaletteDragPayload(this.type);

  final String type;
}

final class NodeDragPayload extends DragPayload {
  const NodeDragPayload(this.nodeId);

  final String nodeId;
}
