import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/fit_scale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('respeita o aspect ratio: usa a menor das duas razões', () {
    final scale = fitScaleFor(
      frame: const Size(400, 200),
      viewport: const Size(300, 100),
    );
    expect(scale, closeTo(0.5, 1e-9));
  });

  test('nunca amplia além de 100%, mesmo com viewport folgado', () {
    final scale = fitScaleFor(
      frame: const Size(300, 400),
      viewport: const Size(2000, 2000),
    );
    expect(scale, 1.0);
  });

  test('tablet num viewport estreito cai bem abaixo do piso 0.4 do zoom '
      'manual — a razão de existir do fit não passar pelo changeZoom (D9)', () {
    const tabletFrame = Size(888.2, 1224);
    final scale = fitScaleFor(
      frame: tabletFrame,
      viewport: const Size(300, 400),
    );
    expect(scale, lessThan(0.4));
  });

  test('é reativo: viewports diferentes produzem escalas diferentes', () {
    const frame = Size(888.2, 1224);
    final wide = fitScaleFor(frame: frame, viewport: const Size(1440, 900));
    final narrow = fitScaleFor(frame: frame, viewport: const Size(700, 500));
    expect(wide, isNot(closeTo(narrow, 1e-9)));
  });

  test(
    'frame ou viewport com dimensão zero/negativa não produz NaN/Infinity',
    () {
      expect(
        fitScaleFor(frame: Size.zero, viewport: const Size(800, 600)).isFinite,
        isTrue,
      );
      expect(
        fitScaleFor(frame: const Size(400, 300), viewport: Size.zero),
        0,
      );
    },
  );
}
