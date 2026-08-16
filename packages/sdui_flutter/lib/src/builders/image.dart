import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/builders/image/image_empty_box.dart';
import 'package:sdui_flutter/src/builders/image/image_error_box.dart';
import 'package:sdui_flutter/src/builders/image/image_loading_box.dart';
import 'package:sdui_flutter/src/layout/sdui_dimension_box.dart';
import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildImage(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final src = (p['src'] ?? '').toString();
  final borderRadius = parseBorderRadius(p['borderRadius']);
  final backgroundColor = parseColor(p['backgroundColor']);
  final semanticLabel = (p['semanticLabel'] as String?)?.trim();

  Widget content;
  if (src.isEmpty) {
    content = const ImageEmptyBox();
  } else {
    final resolvedSrc = _resolve(src, r.imageUrlResolver);

    content = Image.network(
      resolvedSrc,
      fit: boxFitFrom(p['fit']),
      alignment: alignmentFrom(p['alignment']) ?? Alignment.center,
      semanticLabel: semanticLabel != null && semanticLabel.isNotEmpty
          ? semanticLabel
          : null,
      // O callback de progresso do `Image.network` nunca dispara no Flutter
      // Web (`loadViaDecode()` não reporta chunks). `frameBuilder` roda em
      // cada build, nas duas plataformas — `frame == null` é o sinal de
      // "ainda sem pixel decodificado", web e mobile igual.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const ImageLoadingBox();
      },
      errorBuilder: (context, error, stackTrace) => ImageErrorBox(
        reason: _reasonFor(error, showDiagnostics: r.showDiagnostics),
        src: r.showDiagnostics ? src : null,
      ),
    );
  }

  if (backgroundColor != null) {
    content = DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: content,
    );
  }
  if (borderRadius != null) {
    content = ClipRRect(borderRadius: borderRadius, child: content);
  }

  return SduiDimensionBox(
    width: p['width'],
    height: p['height'],
    child: content,
  );
}

/// `src` vazio já retornou antes de chegar aqui; o que resta filtrar é um
/// binding não resolvido (`{{...}}`, sem `scheme`) ou qualquer string que não
/// seja uma URL de rede de verdade — proxyar essas trocaria o estado "vazio"
/// por um "falhou" mentiroso.
String _resolve(String src, SduiImageUrlResolver? resolver) {
  if (resolver == null) return src;
  final uri = Uri.tryParse(src);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return src;
  }
  return resolver(src);
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
