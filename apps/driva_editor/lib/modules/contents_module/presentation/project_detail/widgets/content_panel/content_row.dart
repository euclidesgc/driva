import 'package:flutter/material.dart';

import '../../../../domain/entities/content_summary.dart';
import 'content_row_body.dart';
import 'draggable_content.dart';

class ContentRow extends StatelessWidget {
  const ContentRow({
    super.key,
    required this.content,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final ContentSummary content;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    return DraggableContent(
      content: content,
      childWhenDragging: ContentRowBody(
        content: content,
        onOpen: onOpen,
        onEdit: onEdit,
        onMove: onMove,
        onDelete: onDelete,
        opacity: 0.4,
      ),
      child: ContentRowBody(
        content: content,
        onOpen: onOpen,
        onEdit: onEdit,
        onMove: onMove,
        onDelete: onDelete,
      ),
    );
  }
}
