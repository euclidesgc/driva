import 'package:sdui_flutter/sdui_flutter.dart';

/// Reescreve toda URL de imagem para o proxy de mídia do backend
/// (`GET /v1/media/proxy?url=`), contornando CORS no Flutter Web (item 39).
/// Só o editor liga isto no [SduiRenderer] — o app cliente nunca chama esta
/// função, então nunca herda o tráfego pelo nosso backend.
SduiImageUrlResolver mediaProxyImageUrlResolver(String apiBaseUrl) {
  return (src) => '$apiBaseUrl/v1/media/proxy?url=${Uri.encodeComponent(src)}';
}
