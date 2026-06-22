import 'dart:convert';

/// Mensagens que o editor (pai) envia ao preview (iframe). Lógica pura e
/// testável — o wiring de `postMessage`/`origin` fica em `bridge.dart`.
sealed class PreviewMessage {
  const PreviewMessage();
}

/// Pedido para renderizar um spec (com data/tokens para resolver bindings).
class RenderSpec extends PreviewMessage {
  const RenderSpec({required this.spec, this.data = const {}, this.tokens = const {}});

  final Map<String, dynamic> spec;
  final Map<String, dynamic> data;
  final Map<String, dynamic> tokens;
}

/// Mensagem inválida (payload malformado, tipo desconhecido, etc.).
class PreviewError extends PreviewMessage {
  const PreviewError(this.message);
  final String message;
}

/// Decodifica o payload bruto (string JSON) vindo do editor.
PreviewMessage decodePreviewMessage(String raw) {
  final Object? json;
  try {
    json = jsonDecode(raw);
  } catch (e) {
    return PreviewError('JSON inválido: $e');
  }
  if (json is! Map) return const PreviewError('payload não é um objeto');
  if (json['type'] != 'render') {
    return PreviewError('tipo desconhecido: ${json['type']}');
  }
  final spec = json['spec'];
  if (spec is! Map) return const PreviewError('campo "spec" ausente ou inválido');
  return RenderSpec(
    spec: spec.cast<String, dynamic>(),
    data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    tokens: (json['tokens'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
}

/// Eventos que o preview envia de volta ao editor (saída).
class PreviewEvents {
  const PreviewEvents._();

  static String ready() => jsonEncode({'type': 'ready'});

  static String error(String message) =>
      jsonEncode({'type': 'error', 'message': message});

  static String contentHeight(double height) =>
      jsonEncode({'type': 'height', 'value': height});

  static String tap(String actionType, Map<String, dynamic> params) =>
      jsonEncode({'type': 'action', 'action': actionType, 'params': params});
}
