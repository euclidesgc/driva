import 'package:flutter/material.dart';

/// Botão físico lateral (power/volume) desenhado meio para fora do corpo.
class SideButton extends StatelessWidget {
  const SideButton({
    super.key,
    required this.alignment,
    required this.width,
    required this.color,
    required this.top,
    required this.length,
  });

  final Alignment alignment;
  final double width;
  final Color color;
  final double top;
  final double length;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;
    return Positioned(
      top: top,
      left: left ? -width / 2 : null,
      right: left ? null : -width / 2,
      child: Container(
        width: width,
        height: length,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(
            left: left ? const Radius.circular(3) : Radius.zero,
            right: left ? Radius.zero : const Radius.circular(3),
          ),
        ),
      ),
    );
  }
}
