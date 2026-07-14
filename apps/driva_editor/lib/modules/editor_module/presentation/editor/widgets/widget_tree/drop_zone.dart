import 'package:flutter/material.dart';

import '../drag_payload.dart';
import 'drop_zone_content.dart';

class DropZone extends StatelessWidget {
  const DropZone({super.key, required this.label, required this.onAccept});

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
