import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'incoming.dart';
import 'preview_message.dart';

/// Bridge `postMessage` entre o editor (janela pai) e este preview (iframe).
///
/// - Valida `origin` contra [allowedOrigins] (vazio = aceita qualquer, só dev).
/// - Decodifica mensagens via [processIncoming] (lógica pura em `incoming.dart`).
/// - Envia eventos de volta ao pai com [post]; o `targetOrigin` é a primeira
///   entrada de [allowedOrigins] (least privilege) ou `''` no modo aberto.
/// - Handshake **auto-recuperável**: re-anuncia `ready` até receber o primeiro
///   render. Assim o preview não depende de o editor já estar escutando no
///   exato instante do boot (corrida de timing, iframe recarregando, etc.).
class PreviewBridge {
  PreviewBridge({
    required this.allowedOrigins,
    required this.onRender,
    this.onError,
    this.onInbound,
  });

  final Set<String> allowedOrigins;
  final void Function(RenderSpec render) onRender;
  final void Function(String message)? onError;

  /// Chamado a cada mensagem recebida (qualquer tipo) — usado só p/ diagnóstico.
  final void Function()? onInbound;

  /// Re-anuncia `ready` a cada 300ms até o 1º render, por no máx. ~6s.
  static const Duration _readyInterval = Duration(milliseconds: 300);
  static const int _maxReadyAttempts = 20;

  Timer? _readyRetry;
  bool _gotRender = false;

  String get _targetOrigin =>
      allowedOrigins.isEmpty ? '*' : allowedOrigins.first;

  void start() {
    web.window.addEventListener('message', _onMessage.toJS);
    post(PreviewEvents.ready());

    var attempts = 0;
    _readyRetry = Timer.periodic(_readyInterval, (t) {
      if (_gotRender || attempts++ >= _maxReadyAttempts) {
        t.cancel();
        return;
      }
      post(PreviewEvents.ready());
    });
  }

  void _onMessage(web.Event event) {
    if (event is! web.MessageEvent) return;
    onInbound?.call();
    final raw = event.data;
    final asDart =
        (raw != null && raw.isA<JSString>()) ? (raw as JSString).toDart : null;

    final decision = processIncoming(
      asDart,
      origin: event.origin,
      allowedOrigins: allowedOrigins,
    );
    switch (decision) {
      case OriginRejected():
      case IgnoredNonString():
        return;
      case Processed(message: final msg):
        switch (msg) {
          case RenderSpec():
            _gotRender = true;
            _readyRetry?.cancel();
            onRender(msg);
          case PreviewError(:final message):
            onError?.call(message);
            post(PreviewEvents.error(message));
        }
    }
  }

  /// Envia um evento (string JSON) ao editor pai.
  void post(String payload) {
    web.window.parent?.postMessage(payload.toJS, _targetOrigin.toJS);
  }
}
