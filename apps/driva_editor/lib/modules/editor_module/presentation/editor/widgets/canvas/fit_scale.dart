import 'dart:math' as math;

import 'package:flutter/widgets.dart' show Size;

/// Escala que faz [frame] caber inteiro dentro de [viewport], preservando o
/// aspect ratio (a menor das duas razões — a que não corta nenhuma quina).
///
/// Nunca amplia além de 100%: "ajustar" é fazer caber, não aumentar (D9).
/// Não passa pelo clamp de `EditorCubit.changeZoom` de propósito — é o que
/// permite o preset Tablet, que exige escala abaixo do piso de 0.4 daquele
/// clamp, caber numa janela pequena.
double fitScaleFor({required Size frame, required Size viewport}) {
  if (frame.width <= 0 || frame.height <= 0) return 1;
  if (viewport.width <= 0 || viewport.height <= 0) return 0;
  final scale = math.min(
    viewport.width / frame.width,
    viewport.height / frame.height,
  );
  return math.min(scale, 1);
}
