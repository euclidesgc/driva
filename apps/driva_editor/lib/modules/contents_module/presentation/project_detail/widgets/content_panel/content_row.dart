import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/content_row_body.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/draggable_content.dart';
import 'package:flutter/material.dart';

class ContentRow extends StatelessWidget {
  const ContentRow({
    required this.content,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    super.key,
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
