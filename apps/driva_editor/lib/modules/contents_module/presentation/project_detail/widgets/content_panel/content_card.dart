import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/content_card_body.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/draggable_content.dart';
import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({
    required this.content,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    super.key,
    this.categoryName,
  });

  final ContentSummary content;

  /// Nome da categoria do conteúdo, já resolvido pelo chamador. `null`
  /// quando o mapa ainda não carregou ou não contém o `categoryId` — nesse
  /// caso a linha é omitida (sem placeholder).
  final String? categoryName;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    return DraggableContent(
      content: content,
      childWhenDragging: ContentCardBody(
        content: content,
        categoryName: categoryName,
        onOpen: onOpen,
        onEdit: onEdit,
        onMove: onMove,
        onDelete: onDelete,
        opacity: 0.4,
      ),
      child: ContentCardBody(
        content: content,
        categoryName: categoryName,
        onOpen: onOpen,
        onEdit: onEdit,
        onMove: onMove,
        onDelete: onDelete,
      ),
    );
  }
}
