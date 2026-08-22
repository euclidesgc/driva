import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A cadeia de layout comum aos dois mocks do canvas (rascunho e versão
/// comparada): garante que a `DeviceFrame` do [child] nunca receba
/// constraints tight nos dois eixos ao mesmo tempo, o que a forçaria a um
/// tamanho diferente do seu próprio (distorcendo a moldura). O
/// `InteractiveViewer(constrained: false)` devolve ao [child] constraints
/// ilimitadas nos dois eixos — ele desenha no tamanho intrínseco, e é só
/// então que o `Transform.scale` reduz visualmente sem espremer.
class CanvasMockViewport extends StatelessWidget {
  const CanvasMockViewport({
    required this.effectiveScale,
    required this.child,
    super.key,
  });

  final double effectiveScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(AppSpacing.s64),
      minScale: 1,
      maxScale: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Transform.scale(
          scale: effectiveScale,
          alignment: Alignment.topCenter,
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
