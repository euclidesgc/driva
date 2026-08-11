import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sem isto os goldens saem com o fallback "tofu"/Ahem e os ícones viram
/// caixas vazias.
///
/// As famílias vêm do `FontManifest.json` do próprio bundle de teste — o que
/// cobre as fontes do app **e** o `MaterialIcons` do `uses-material-design`,
/// sem depender do cwd. A versão anterior montava caminhos relativos e, da
/// raiz do repo (como faz a CI), pulava tudo em silêncio: os goldens foram
/// gravados sem tipografia nem ícones reais.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;

  if (manifest.isEmpty) {
    throw StateError(
      'FontManifest.json vazio — rode a suíte de dentro de apps/driva_editor; '
      'da raiz do repo o bundle de assets não é montado e os goldens sairiam '
      'sem fontes',
    );
  }

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family']! as String);
    for (final font
        in (entry['fonts']! as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }
}
