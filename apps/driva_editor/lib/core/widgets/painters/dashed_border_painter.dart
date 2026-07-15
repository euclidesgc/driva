import 'package:flutter/material.dart';

/// Pinta uma borda tracejada retangular ao redor da área do filho, sem
/// dependência externa. Usada para dar percepção de "há algo aqui" a cada nó
/// do mock (útil quando o componente é pequeno ou vazio).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 4,
    this.gapLength = 3,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addRect(Offset.zero & size);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      final step = dashLength + gapLength;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += step;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        gapLength != oldDelegate.gapLength;
  }
}
