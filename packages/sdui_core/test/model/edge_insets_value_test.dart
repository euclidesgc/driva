import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('EdgeInsetsValue.modeOf', () {
    test('{all: 8} é uniforme', () {
      expect(EdgeInsetsValue.modeOf({'all': 8}), EdgeInsetsMode.uniform);
    });

    test('quatro lados iguais é uniforme', () {
      expect(
        EdgeInsetsValue.modeOf({'left': 8, 'top': 8, 'right': 8, 'bottom': 8}),
        EdgeInsetsMode.uniform,
      );
    });

    test('lados diferentes é por lado', () {
      expect(
        EdgeInsetsValue.modeOf({'left': 8, 'top': 4, 'right': 8, 'bottom': 4}),
        EdgeInsetsMode.perSide,
      );
    });

    test('ausente é uniforme', () {
      expect(EdgeInsetsValue.modeOf(null), EdgeInsetsMode.uniform);
    });

    test('um lado só, com os outros ausentes, é por lado', () {
      expect(EdgeInsetsValue.modeOf({'top': 8}), EdgeInsetsMode.perSide);
    });

    test('valor que não é Map é uniforme', () {
      expect(EdgeInsetsValue.modeOf('8'), EdgeInsetsMode.uniform);
      expect(EdgeInsetsValue.modeOf(8), EdgeInsetsMode.uniform);
    });
  });

  group('EdgeInsetsValue.sideOf', () {
    test('all vale para os quatro lados', () {
      for (final side in EdgeInsetsValue.sides) {
        expect(EdgeInsetsValue.sideOf({'all': 8}, side), 8.0);
      }
    });

    test('sem all lê o lado pedido', () {
      const raw = {'left': 4, 'top': 8};

      expect(EdgeInsetsValue.sideOf(raw, 'left'), 4.0);
      expect(EdgeInsetsValue.sideOf(raw, 'top'), 8.0);
      expect(EdgeInsetsValue.sideOf(raw, 'right'), isNull);
    });

    test('não-Map dá null', () {
      expect(EdgeInsetsValue.sideOf(null, 'left'), isNull);
      expect(EdgeInsetsValue.sideOf('8', 'left'), isNull);
    });
  });

  group('EdgeInsetsValue.uniformOf', () {
    test('devolve o all', () {
      expect(EdgeInsetsValue.uniformOf({'all': 12}), 12.0);
    });

    test('devolve o valor comum dos quatro lados', () {
      expect(
        EdgeInsetsValue.uniformOf({
          'left': 8,
          'top': 8,
          'right': 8,
          'bottom': 8,
        }),
        8.0,
      );
    });

    test('lados diferentes ou parciais dão null', () {
      expect(EdgeInsetsValue.uniformOf({'left': 8, 'top': 4}), isNull);
      expect(EdgeInsetsValue.uniformOf({'top': 8}), isNull);
    });

    test('ausente ou não-Map dá null', () {
      expect(EdgeInsetsValue.uniformOf(null), isNull);
      expect(EdgeInsetsValue.uniformOf('8'), isNull);
    });
  });
}
