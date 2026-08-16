import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/network/media_proxy_image_url_resolver.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// `apiBaseUrl` vazio (`String.fromEnvironment` sem
/// `--dart-define-from-file`) viraria `/v1/media/proxy?url=…` — relativo
/// à origem de quem chama, que não serve esse caminho. Sem servidor real
/// (`useFakeData`), o mesmo proxy aponta para um backend que não existe.
/// Nos dois casos o resolver precisa ficar `null`: sem ele o builder busca
/// a imagem direto do host, que é o comportamento de antes do item 39 —
/// degradação correta, não a tela "falhou" generalizada que reintroduziria
/// o sintoma que aquele item corrigiu.
///
/// Fábrica compartilhada (item 41, D6): toda página que renderiza SDUI
/// (`EditorPage`, `PreviewPage`) chama esta mesma função a partir do seu
/// `pageBuilder` — duplicar a guarda por página é como a regressão do item 39
/// volta.
SduiImageUrlResolver? imageUrlResolverFor(AppConfig config) {
  if (config.apiBaseUrl.isEmpty || config.useFakeData) return null;
  return mediaProxyImageUrlResolver(config.apiBaseUrl);
}
