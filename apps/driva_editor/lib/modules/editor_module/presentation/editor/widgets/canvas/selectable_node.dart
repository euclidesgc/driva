import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/painters/painters.dart';
import 'node_tag.dart';

/// Contorno + rótulo sobre o widget renderizado.
///
/// Seleção = contorno sólido + tag destacada. Fora de seleção, cada nó recebe
/// uma **borda tracejada discreta + tag pequena com o nome**, para o usuário
/// perceber que há um componente ali mesmo quando ele é pequeno ou vazio
/// (feedback ao soltar no mock).
///
/// `spacer`/tipos de flex NÃO são envolvidos (precisam ser filhos diretos de
/// Row/Column) — eles se selecionam pela árvore.
class SelectableNode extends StatelessWidget {
  const SelectableNode({
    super.key,
    required this.node,
    required this.built,
    required this.isSelected,
    required this.isHovered,
    required this.onSelect,
    required this.onHover,
  });

  final SduiNode node;
  final Widget built;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onSelect;
  final ValueChanged<bool> onHover;

  static const _unwrappable = {'spacer'};
  static const _hintColor = Color(0x66A0A4AD);

  /// Contorno de hover: laranja da marca com opacidade baixa — reforço leve,
  /// abaixo da seleção sólida na precedência. A tag/nome continuam sendo o
  /// sinal permanente (o hover não é o único indicador).
  static final _hoverColor = AppTheme.primary.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    if (_unwrappable.contains(node.type)) return built;

    final descriptor = descriptorFor(node.type);
    final label = descriptor?.label ?? node.type;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: Semantics(
          label: label,
          selected: isSelected,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSelected)
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: built,
                )
              else if (isHovered)
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(color: _hoverColor, width: 1.5),
                  ),
                  child: built,
                )
              else
                CustomPaint(
                  foregroundPainter: const DashedBorderPainter(
                    color: _hintColor,
                  ),
                  child: built,
                ),
              Positioned(
                top: -18,
                left: 0,
                child: NodeTag(label: label, isSelected: isSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
