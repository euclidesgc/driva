import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/builders/image/image_empty_box.dart';
import 'package:sdui_flutter/src/builders/image/image_error_box.dart';
import 'package:sdui_flutter/src/builders/image/image_loading_box.dart';
import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildImage(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final src = (p['src'] ?? '').toString();
  final width = parseDouble(p['width']);
  final height = parseDouble(p['height']);

  if (src.isEmpty) {
    return ImageEmptyBox(width: width, height: height);
  }

  return Image.network(
    src,
    width: width,
    height: height,
    fit: boxFitFrom(p['fit']),
    // O callback de progresso do `Image.network` nunca dispara no Flutter Web
    // (`loadViaDecode()` não reporta chunks). `frameBuilder` roda em todo
    // build nas duas plataformas — `frame == null` é o sinal de "ainda sem
    // pixel decodificado", web e mobile igual.
    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded || frame != null) return child;
      return ImageLoadingBox(width: width, height: height);
    },
    errorBuilder: (context, error, stackTrace) => ImageErrorBox(
      reason: _reasonFor(error, showDiagnostics: r.showDiagnostics),
      src: r.showDiagnostics ? src : null,
      width: width,
      height: height,
    ),
  );
}

/// Fora do editor (`showDiagnostics: false`) o app publicado nunca mostra
/// `error.toString()` cru nem a URL: `NetworkImageLoadException._message`
/// embute a própria URL (`'HTTP request failed, statusCode: $c, $uri'`), e
/// omitir só o `src` não bastaria.
String _reasonFor(Object error, {required bool showDiagnostics}) {
  if (showDiagnostics) return error.toString();
  if (error is NetworkImageLoadException) return 'HTTP ${error.statusCode}';
  return 'não foi possível carregar';
}
