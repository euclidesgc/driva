import 'dart:io';

import 'package:flutter/services.dart';

/// Sem isto os goldens saem com o fallback "tofu"/Ahem. Os caminhos são
/// relativos à raiz do pacote (`apps/driva_editor`), o cwd do `flutter test`.
Future<void> loadAppFonts() async {
  await _loadFamily('Public Sans', const [
    'fonts/public_sans/PublicSans-Regular.ttf',
    'fonts/public_sans/PublicSans-Medium.ttf',
    'fonts/public_sans/PublicSans-SemiBold.ttf',
    'fonts/public_sans/PublicSans-Bold.ttf',
  ]);
  await _loadFamily('Space Grotesk', const [
    'fonts/space_grotesk/SpaceGrotesk-Medium.ttf',
    'fonts/space_grotesk/SpaceGrotesk-Bold.ttf',
  ]);
}

Future<void> _loadFamily(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = await file.readAsBytes();
    loader.addFont(
      Future<ByteData>.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  await loader.load();
}
