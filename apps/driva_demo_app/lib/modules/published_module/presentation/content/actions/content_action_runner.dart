import 'package:driva_demo_app/core/platform/url_opener.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/actions/content_messenger.dart';
import 'package:flutter/services.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

class ContentActionRunner {
  const ContentActionRunner({
    required this.onNavigate,
    required this.onNavigateBack,
    required this.showMessage,
    required this.urlOpener,
  });

  static const defaultSnackBarDuration = Duration(milliseconds: 4000);
  static const linkFailureMessage = 'Não foi possível abrir o link.';

  final ValueChanged<String> onNavigate;
  final VoidCallback onNavigateBack;
  final ContentMessenger showMessage;
  final UrlOpener urlOpener;

  Future<void> run(SduiAction action) async {
    switch (action.type) {
      case 'navigate':
        final slug = _literal(action.params['slug']);
        if (slug == null) return _announce(action);
        onNavigate(slug.trim());
      case 'navigateBack':
        onNavigateBack();
      case 'showSnackBar':
        final message = _literal(action.params['message']);
        if (message == null) return _announce(action);
        showMessage(
          message,
          duration: _durationFrom(action.params['durationMs']),
          backgroundColor: parseColor(action.params['backgroundColor']),
        );
      case 'copyToClipboard':
        final text = _literal(action.params['text']);
        if (text == null) return _announce(action);
        await Clipboard.setData(ClipboardData(text: text));
      case 'launchUrl':
        final url = _literal(action.params['url']);
        if (url == null) return _announce(action);
        await _launch(url.trim());
      default:
        _announce(action);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    final opened = uri != null && uri.hasScheme && await urlOpener(uri);
    if (!opened) showMessage(linkFailureMessage);
  }

  void _announce(SduiAction action) {
    final params = action.params.isEmpty ? '' : ' ${action.params}';
    showMessage('Ação recebida: "${action.type}"$params');
  }

  static String? _literal(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static Duration _durationFrom(Object? value) => value is num && value >= 0
      ? Duration(milliseconds: value.round())
      : defaultSnackBarDuration;
}
