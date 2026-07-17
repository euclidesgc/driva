import 'package:driva_editor/core/widgets/layout/resize_handle.dart';
import 'package:flutter/material.dart';

class ResizableSplitView extends StatefulWidget {
  const ResizableSplitView({
    required this.left,
    required this.center,
    required this.right,
    super.key,
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
        ResizeHandle(
          onDrag: (dx) => setState(() => _leftWidth = _clamp(_leftWidth + dx)),
        ),
        Expanded(child: widget.center),
        ResizeHandle(
          onDrag: (dx) =>
              setState(() => _rightWidth = _clamp(_rightWidth - dx)),
        ),
        SizedBox(width: _rightWidth, child: widget.right),
      ],
    );
  }
}
