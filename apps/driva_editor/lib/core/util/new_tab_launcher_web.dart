import 'package:web/web.dart' as web;

/// Abre `url` numa aba nova do navegador — usado pelo diálogo de preview
/// (item 41) para "abrir em nova aba", ao lado da URL copiável.
class NewTabLauncherImpl {
  const NewTabLauncherImpl();

  void open(String url) {
    web.window.open(url, '_blank');
  }
}
