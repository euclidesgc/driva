import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Reexporta o carregador de fontes reais: cada golden test só precisa importar
// este helper para chamar `loadAppFonts()` + `installTolerantGoldenComparator()`
// no `setUpAll`.
export 'app_fonts.dart' show loadAppFonts;

/// Troca o `goldenFileComparator` global por um [_TolerantComparator] que aceita
/// uma diferença até [threshold] (0..1). Absorve o ruído subpixel das fontes
/// reais (o antialiasing varia ~2-3% entre contextos de execução) sem mascarar
/// regressões estruturais/de layout. Idempotente por arquivo de teste.
///
/// `flutter test` roda cada arquivo num isolate próprio, então o
/// `goldenFileComparator` chega aqui como o `LocalFileComparator` padrão do
/// arquivo corrente (seu `basedir` aponta para a pasta do teste). Preservamos
/// esse `basedir` ao embrulhar.
Future<void> installTolerantGoldenComparator({double threshold = 0.05}) async {
  final previous = goldenFileComparator;
  if (previous is _TolerantComparator) return;
  if (previous is! LocalFileComparator) return;
  goldenFileComparator = _TolerantComparator(
    previous.basedir,
    threshold: threshold,
  );
}

/// Comparador de golden que aceita uma diferença até [threshold] (0..1) — o
/// suficiente para absorver o ruído subpixel das fontes reais sem mascarar
/// regressões visuais reais. Falha (com output de diff) acima do limite.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(Uri baseDir, {required this.threshold})
    : super(baseDir.resolve('placeholder_test.dart'));

  final double threshold;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent <= threshold) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
