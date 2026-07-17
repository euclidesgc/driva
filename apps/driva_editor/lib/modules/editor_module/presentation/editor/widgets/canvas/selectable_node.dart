import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:driva_editor/core/widgets/painters/painters.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/node_tag.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// `spacer` não é envolvido: precisa ser filho direto de Row/Column.
class SelectableNode extends StatelessWidget {
  const SelectableNode({
    required this.node,
    required this.built,
    required this.isSelected,
    required this.isHovered,
    required this.onSelect,
    required this.onHover,
    super.key,
  });

  final SduiNode node;
  final Widget built;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onSelect;
  final ValueChanged<bool> onHover;

  static const _unwrappable = {'spacer'};

  static final Color _hoverColor = AppTheme.primary.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    if (_unwrappable.contains(node.type)) return built;

    final mock = Theme.of(context).extension<DeviceMockColors>()!;
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
                  foregroundPainter: DashedBorderPainter(color: mock.dropHint),
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
