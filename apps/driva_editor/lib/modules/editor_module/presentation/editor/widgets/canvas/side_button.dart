import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:flutter/material.dart';

class SideButton extends StatelessWidget {
  const SideButton({
    required this.alignment,
    required this.width,
    required this.color,
    required this.top,
    required this.length,
    super.key,
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
            left: left ? const Radius.circular(AppRadii.r3) : Radius.zero,
            right: left ? Radius.zero : const Radius.circular(AppRadii.r3),
          ),
        ),
      ),
    );
  }
}
