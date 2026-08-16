import 'dart:math' as math;

import 'package:driva_editor/core/theme/app_sizes.dart';
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
    this.minPanelWidth = AppSizes.workspacePanelMinWidth,
    this.maxPanelWidth = 480,
    this.minCenterWidth = AppSizes.minCenterWidth,
  });

  final Widget left;
  final Widget center;
  final Widget right;
  final double initialLeftWidth;
  final double initialRightWidth;
  final double minPanelWidth;
  final double maxPanelWidth;
  final double minCenterWidth;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final floor =
            2 * widget.minPanelWidth +
            AppSizes.workspaceDividersWidth +
            widget.minCenterWidth;
        final storedRequirement =
            _leftWidth +
            _rightWidth +
            AppSizes.workspaceDividersWidth +
            widget.minCenterWidth;
        final storedWidthsFit = constraints.maxWidth >= storedRequirement;

        final leftWidth = storedWidthsFit ? _leftWidth : widget.minPanelWidth;
        final rightWidth = storedWidthsFit ? _rightWidth : widget.minPanelWidth;

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: leftWidth, child: widget.left),
            ResizeHandle(
              onDrag: (dx) =>
                  setState(() => _leftWidth = _clamp(leftWidth + dx)),
            ),
            Expanded(child: widget.center),
            ResizeHandle(
              onDrag: (dx) =>
                  setState(() => _rightWidth = _clamp(rightWidth - dx)),
            ),
            SizedBox(width: rightWidth, child: widget.right),
          ],
        );

        final rowWidth = math.max(constraints.maxWidth, floor);
        if (rowWidth <= constraints.maxWidth) {
          return row;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: rowWidth, child: row),
        );
      },
    );
  }
}
