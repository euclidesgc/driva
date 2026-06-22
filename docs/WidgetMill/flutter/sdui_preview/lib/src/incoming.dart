import 'preview_message.dart';

/// Decisão da bridge ao receber uma mensagem — **lógica pura e testável**.
///
/// Vive separada de `bridge.dart` (que importa `package:web`/`dart:js_interop`,
/// indisponíveis na VM) para poder ser exercida por testes de unidade comuns.
sealed class IncomingDecision {
  const IncomingDecision();
}

/// Origem rejeitada — a mensagem é ignorada silenciosamente.
class OriginRejected extends IncomingDecision {
  const OriginRejected();
}

/// Tipo de payload inválido (não-string ou nulo) — ignorado.
class IgnoredNonString extends IncomingDecision {
  const IgnoredNonString();
}

/// Mensagem processada (render ou error).
class Processed extends IncomingDecision {
  const Processed(this.message);
  final PreviewMessage message;
}

/// Converte uma lista separada por vírgulas (ex.: de `--dart-define`) num set de
/// origens permitidas. Vazio → set vazio (modo aberto — apenas dev).
Set<String> parseAllowedOrigins(String raw) {
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
}

/// Decide o que fazer com um payload bruto e a origem dele.
IncomingDecision processIncoming(
  Object? rawData, {
  required String? origin,
  required Set<String> allowedOrigins,
}) {
  if (allowedOrigins.isNotEmpty &&
      (origin == null || !allowedOrigins.contains(origin))) {
    return const OriginRejected();
  }
  if (rawData is! String) return const IgnoredNonString();
  return Processed(decodePreviewMessage(rawData));
}
