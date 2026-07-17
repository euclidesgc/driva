import 'package:driva_editor/modules/projects_module/presentation/widgets/grid_texture_painter.dart';
import 'package:flutter/material.dart';

class GradientTexture extends StatelessWidget {
  const GradientTexture({required this.gradient, super.key});

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
