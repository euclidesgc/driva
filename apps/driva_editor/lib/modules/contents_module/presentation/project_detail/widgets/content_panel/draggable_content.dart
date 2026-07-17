import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/card_actions.dart'
    show CardActions;
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/content_drag_chip.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/content_panel.dart'
    show CardActions;
import 'package:flutter/material.dart';

/// O botão "mover" de [CardActions] permanece como caminho acessível
/// primário — o drag é só um atalho, nunca o único sinal (D6/CA10).
class DraggableContent extends StatelessWidget {
  const DraggableContent({
    required this.content,
    required this.child,
    required this.childWhenDragging,
    super.key,
  });

  final ContentSummary content;
  final Widget child;
  final Widget childWhenDragging;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Arraste para mover de categoria',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Semantics(
          label: 'Conteúdo ${content.name}. Arraste para mover de categoria.',
          child: Draggable<ContentSummary>(
            data: content,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: FractionalTranslation(
              translation: const Offset(0.2, -1.15),
              child: ContentDragChip(content: content),
            ),
            childWhenDragging: childWhenDragging,
            child: child,
          ),
        ),
      ),
    );
  }
}
