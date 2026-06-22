import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_preview/src/preview_message.dart';

void main() {
  group('decodePreviewMessage', () {
    test('render válido vira RenderSpec com data/tokens', () {
      final raw = jsonEncode({
        'type': 'render',
        'spec': {'type': 'text', 'props': {'data': '{{x}}'}},
        'data': {'x': 'Oi'},
        'tokens': {'primary': '#1565C0'},
      });
      final msg = decodePreviewMessage(raw);
      expect(msg, isA<RenderSpec>());
      final render = msg as RenderSpec;
      expect(render.spec['type'], 'text');
      expect(render.data['x'], 'Oi');
      expect(render.tokens['primary'], '#1565C0');
    });

    test('JSON inválido vira PreviewError', () {
      expect(decodePreviewMessage('{nao-json'), isA<PreviewError>());
    });

    test('tipo desconhecido vira PreviewError', () {
      expect(
        decodePreviewMessage(jsonEncode({'type': 'foo'})),
        isA<PreviewError>(),
      );
    });

    test('spec ausente vira PreviewError', () {
      expect(
        decodePreviewMessage(jsonEncode({'type': 'render'})),
        isA<PreviewError>(),
      );
    });
  });

  group('PreviewEvents', () {
    test('serializa eventos de saída', () {
      expect(jsonDecode(PreviewEvents.ready())['type'], 'ready');
      expect(jsonDecode(PreviewEvents.error('x'))['message'], 'x');
      expect(jsonDecode(PreviewEvents.contentHeight(42))['value'], 42);
      final tap = jsonDecode(PreviewEvents.tap('navigate', {'routeId': 'r'}));
      expect(tap['action'], 'navigate');
      expect(tap['params']['routeId'], 'r');
    });
  });
}
