import 'package:flutter/material.dart';

import '../editor_colors.dart';

/// Layout de 3 colunas com divisores arrastáveis (padrão de editor desktop):
/// painel esquerdo e direito com largura ajustável, centro flexível.
class ResizableSplitView extends StatefulWidget {
  const ResizableSplitView({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.initialLeftWidth = 280,
    this.initialRightWidth = 320,
    this.minPanelWidth = 200,
    this.maxPanelWidth = 480,
  });

  final Widget left;
  final Widget center;
  final Widget right;
  final double initialLeftWidth;
  final double initialRightWidth;
  final double minPanelWidth;
  final double maxPanelWidth;

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _leftWidth = widget.initialLeftWidth;
  late double _rightWidth = widget.initialRightWidth;

  double _clamp(double value) =>
      value.clamp(widget.minPanelWidth, widget.maxPanelWidth);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: _leftWidth, child: widget.left),
        _ResizeHandle(
          onDrag: (dx) => setState(() => _leftWidth = _clamp(_leftWidth + dx)),
        ),
        Expanded(child: widget.center),
        _ResizeHandle(
          onDrag: (dx) =>
              setState(() => _rightWidth = _clamp(_rightWidth - dx)),
        ),
        SizedBox(width: _rightWidth, child: widget.right),
      ],
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: SizedBox(
          width: 6,
          child: Center(
            child: SizedBox(width: 1, child: ColoredBox(color: colors.border)),
          ),
        ),
      ),
    );
  }
}
