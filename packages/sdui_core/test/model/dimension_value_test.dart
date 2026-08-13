import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('parse', () {
    test('número cru é pixels — todo spec já escrito segue válido', () {
      expect(DimensionValue.parse(100), const PixelDimension(100));
      expect(DimensionValue.parse(12.5), const PixelDimension(12.5));
      expect(DimensionValue.parse(0), const PixelDimension(0));
    });

    test('sufixo de porcentagem vira fração', () {
      expect(DimensionValue.parse('70%'), const PercentDimension(0.7));
      expect(DimensionValue.parse('100%'), const PercentDimension(1));
      expect(DimensionValue.parse('0%'), const PercentDimension(0));
      expect(DimensionValue.parse('12.5%'), const PercentDimension(0.125));
      expect(DimensionValue.parse('12,5%'), const PercentDimension(0.125));
      expect(DimensionValue.parse(' 70 % '), const PercentDimension(0.7));
    });

    test('token de preencher', () {
      expect(DimensionValue.parse('inf'), const InfiniteDimension());
      expect(DimensionValue.parse(' inf '), const InfiniteDimension());
    });

    test('devolve null para o que não é dimensão', () {
      expect(DimensionValue.parse(null), isNull);
      expect(DimensionValue.parse(''), isNull);
      expect(DimensionValue.parse('abc'), isNull);
      expect(DimensionValue.parse('70'), isNull);
      expect(DimensionValue.parse('70%%'), isNull);
      expect(DimensionValue.parse('%'), isNull);
      expect(DimensionValue.parse('-70%'), isNull);
      expect(DimensionValue.parse('infinito'), isNull);
      expect(DimensionValue.parse(true), isNull);
      expect(DimensionValue.parse(<String, dynamic>{}), isNull);
    });

    test('binding não é dimensão: quem trata é a camada do editor', () {
      expect(DimensionValue.parse('{{produto.largura}}'), isNull);
    });
  });

  group('toJson', () {
    test('roundtrip é idempotente', () {
      for (final raw in <Object>[100, 12.5, '70%', '100%', 'inf']) {
        expect(
          DimensionValue.parse(raw)!.toJson(),
          raw is num ? raw.toDouble() : raw,
          reason: 'roundtrip de $raw',
        );
      }
    });

    test('porcentagem redonda não carrega casa decimal', () {
      expect(const PercentDimension(0.7).toJson(), '70%');
      expect(const PercentDimension(1).toJson(), '100%');
      expect(const PercentDimension(0.125).toJson(), '12.5%');
    });
  });
}
