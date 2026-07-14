import 'package:flutter/material.dart';

import '../../../../domain/entities/content_summary.dart';
import 'content_drag_chip.dart';

/// Origem do drag-and-drop (feature 10, fase 2): embrulha o card/linha num
/// `Draggable<ContentSummary>` com chip de feedback compacto, origem
/// esmaecida enquanto arrasta e cursor "grab" + tooltip curta na origem.
///
/// O botão "mover" de [CardActions] permanece como caminho acessível
/// primário — o drag é só um atalho, nunca o único sinal (D6/CA10).
class DraggableContent extends StatelessWidget {
  const DraggableContent({
    super.key,
    required this.content,
    required this.child,
    required this.childWhenDragging,
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
