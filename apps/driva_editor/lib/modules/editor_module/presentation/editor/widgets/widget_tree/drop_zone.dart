import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/drop_zone_content.dart';
import 'package:flutter/material.dart';

class DropZone extends StatelessWidget {
  const DropZone({required this.label, required this.onAccept, super.key});

  final String label;
  final ValueChanged<DragPayload> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragPayload>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) =>
          DropZoneContent(isDragOver: candidates.isNotEmpty, label: label),
    );
  }
}
