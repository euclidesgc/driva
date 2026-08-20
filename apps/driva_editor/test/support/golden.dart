import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

export 'app_fonts.dart' show loadAppFonts;

/// O antialiasing das fontes reais varia ~2-3% entre contextos de execução.
Future<void> installTolerantGoldenComparator({double threshold = 0.05}) async {
  final previous = goldenFileComparator;
  if (previous is _TolerantComparator) return;
  if (previous is! LocalFileComparator) return;
  goldenFileComparator = _TolerantComparator(
    previous.basedir,
    threshold: threshold,
  );
}

/// Aperta a tolerância para um golden específico dentro do arquivo, sem
/// afetar os outros: o padrão de 5% (acima) existe para a página inteira,
/// mas um rótulo cortado por `ellipsis` some numa fração pequena da
/// imagem — perto de 3% num crop pequeno — e passaria batido nesse teto.
/// Restaura o comparador anterior ao final, mesmo se [body] lançar.
Future<void> withStricterGolden(
  double threshold,
  Future<void> Function() body,
) async {
  final previous = goldenFileComparator;
  if (previous is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(
      previous.basedir,
      threshold: threshold,
    );
  }
  try {
    await body();
  } finally {
    goldenFileComparator = previous;
  }
}

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
