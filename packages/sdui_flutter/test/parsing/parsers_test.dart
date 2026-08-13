import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';

void main() {
  group('parseDouble', () {
    test('converte número', () {
      expect(parseDouble(12), 12.0);
      expect(parseDouble(12.5), 12.5);
    });

    test('devolve null para ausência', () {
      expect(parseDouble(null), isNull);
    });

    test('devolve null em vez de lançar para valor não numérico', () {
      expect(parseDouble('{{produto.largura}}'), isNull);
      expect(parseDouble('100'), isNull);
      expect(parseDouble(true), isNull);
      expect(parseDouble(<String, dynamic>{}), isNull);
    });
  });

  group('parseInt', () {
    test('converte número', () {
      expect(parseInt(3), 3);
      expect(parseInt(3.7), 3);
    });

    test('devolve null em vez de lançar para valor não numérico', () {
      expect(parseInt(null), isNull);
      expect(parseInt('{{tema.linhas}}'), isNull);
      expect(parseInt('3'), isNull);
    });
  });

  group('parseBorderRadius', () {
    test('devolve null em vez de lançar para valor não numérico', () {
      expect(parseBorderRadius('{{tema.raio}}'), isNull);
      expect(parseBorderRadius(null), isNull);
    });
  });

  group('parseColor', () {
    test('devolve null em vez de lançar para valor inválido', () {
      expect(parseColor('{{tema.cor}}'), isNull);
      expect(parseColor('vermelho'), isNull);
      expect(parseColor(0xFF0000), isNull);
    });

    test('aceita as duas larguras de hex', () {
      expect(parseColor('#FF0000')?.toARGB32(), 0xFFFF0000);
      expect(parseColor('#80FF0000')?.toARGB32(), 0x80FF0000);
    });
  });

  group('parseEdgeInsets', () {
    test('devolve null em vez de lançar para valor não-mapa', () {
      expect(parseEdgeInsets('{{tema.espaco}}'), isNull);
      expect(parseEdgeInsets(8), isNull);
    });
  });
}
