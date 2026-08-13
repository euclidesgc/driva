import 'package:flutter/widgets.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';

/// Aplica largura/altura do spec (pixels, percentual do pai ou "preenche") e
/// os limites mínimo/máximo, resolvendo o percentual contra o espaço real.
///
/// Usa `LayoutBuilder` porque é o único jeito de ler o extent do pai nos dois
/// eixos: `FractionallySizedBox` crava constraint tight (assert em extent
/// infinito), não compõe com pixels no outro eixo e anula min/max. O custo é
/// perder intrinsics — nenhum primitivo do catálogo pede intrinsics de filho
/// arbitrário hoje, mas incluir `IntrinsicHeight`/`Table` exigirá rever isto.
class SduiDimensionBox extends StatelessWidget {
  const SduiDimensionBox({
    required this.child,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    super.key,
  });

  final Widget child;
  final Object? width;
  final Object? height;
  final Object? minWidth;
  final Object? maxWidth;
  final Object? minHeight;
  final Object? maxHeight;

  bool get _isNoOp =>
      width == null &&
      height == null &&
      minWidth == null &&
      maxWidth == null &&
      minHeight == null &&
      maxHeight == null;

  /// O tamanho pedido não compete com os limites: ele é o alvo, e min/max o
  /// mantêm na faixa. Sem isso, `width: inf` com `maxWidth: 200` ignoraria o
  /// teto.
  static ({double min, double max}) _axis({
    required Object? size,
    required Object? minSize,
    required Object? maxSize,
    required double available,
  }) {
    final min = resolveDimension(minSize, available) ?? 0;
    final max = resolveDimension(maxSize, available) ?? double.infinity;
    final target = resolveDimension(size, available);
    if (target == null) return (min: min, max: max);

    final clamped = target.clamp(min, max);
    return (min: clamped, max: clamped);
  }

  BoxConstraints _constraintsFor(BoxConstraints incoming) {
    final horizontal = _axis(
      size: width,
      minSize: minWidth,
      maxSize: maxWidth,
      available: incoming.maxWidth,
    );
    final vertical = _axis(
      size: height,
      minSize: minHeight,
      maxSize: maxHeight,
      available: incoming.maxHeight,
    );

    return BoxConstraints(
      minWidth: horizontal.min,
      maxWidth: horizontal.max,
      minHeight: vertical.min,
      maxHeight: vertical.max,
    ).enforce(incoming);
  }

  @override
  Widget build(BuildContext context) {
    if (_isNoOp) return child;
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: _constraintsFor(constraints),
        child: child,
      ),
    );
  }
}
