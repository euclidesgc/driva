import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpener = Future<bool> Function(Uri url);

/// Fronteira com a plataforma: o `launchUrl` sinaliza falha devolvendo `false`
/// ou lançando `PlatformException`, e as duas viram `false` para a tela.
Future<bool> openUrlExternally(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}
