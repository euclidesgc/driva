import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_preview/src/incoming.dart';
import 'package:sdui_preview/src/preview_message.dart';

const _render = '{"type":"render","spec":{"type":"text","props":{"data":"x"}}}';

void main() {
  group('processIncoming — validação de origem', () {
    test('origem fora da allowlist é rejeitada', () {
      final d = processIncoming(
        _render,
        origin: 'https://evil.com',
        allowedOrigins: {'https://app.com'},
      );
      expect(d, isA<OriginRejected>());
    });

    test('origem na allowlist é processada', () {
      final d = processIncoming(
        _render,
        origin: 'https://app.com',
        allowedOrigins: {'https://app.com'},
      );
      expect(d, isA<Processed>());
      expect((d as Processed).message, isA<RenderSpec>());
    });

    test('allowlist vazia aceita qualquer origem (modo dev)', () {
      final d = processIncoming(
        _render,
        origin: 'https://qualquer.com',
        allowedOrigins: const {},
      );
      expect(d, isA<Processed>());
    });

    test('origin nulo com allowlist definida é rejeitado', () {
      final d = processIncoming(
        _render,
        origin: null,
        allowedOrigins: {'https://app.com'},
      );
      expect(d, isA<OriginRejected>());
    });
  });

  group('parseAllowedOrigins', () {
    test('vazio → set vazio (modo aberto)', () {
      expect(parseAllowedOrigins(''), isEmpty);
    });

    test('lista separada por vírgula, com trim', () {
      expect(
        parseAllowedOrigins('https://a.com, https://b.com '),
        {'https://a.com', 'https://b.com'},
      );
    });

    test('ignora entradas vazias', () {
      expect(parseAllowedOrigins('https://a.com,,'), {'https://a.com'});
    });
  });

  group('processIncoming — payload', () {
    test('payload não-string é ignorado', () {
      final d = processIncoming(42, origin: null, allowedOrigins: const {});
      expect(d, isA<IgnoredNonString>());
    });

    test('payload válido vira Processed(RenderSpec)', () {
      final raw = jsonEncode({
        'type': 'render',
        'spec': {'type': 'text', 'props': {'data': 'oi'}},
        'data': {'k': 'v'},
      });
      final d = processIncoming(raw, origin: null, allowedOrigins: const {});
      expect((d as Processed).message, isA<RenderSpec>());
    });

    test('payload malformado vira Processed(PreviewError)', () {
      final d = processIncoming('{nao json', origin: null, allowedOrigins: const {});
      expect((d as Processed).message, isA<PreviewError>());
    });
  });
}
