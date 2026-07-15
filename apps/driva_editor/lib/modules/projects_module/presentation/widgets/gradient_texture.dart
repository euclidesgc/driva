import 'package:flutter/material.dart';

import 'grid_texture_painter.dart';

class GradientTexture extends StatelessWidget {
  const GradientTexture({super.key, required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Opacity(
        opacity: 0.16,
        child: CustomPaint(painter: GridTexturePainter()),
      ),
    );
  }
}
