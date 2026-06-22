import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';

void main() {
  group('parseColor', () {
    test('RRGGBB assume alpha FF', () {
      expect(parseColor('#1565C0'), const Color(0xFF1565C0));
    });
    test('AARRGGBB', () {
      expect(parseColor('#8001020A'), const Color(0x8001020A));
    });
    test('nulo/ inválido retorna null', () {
      expect(parseColor(null), isNull);
      expect(parseColor('red'), isNull);
    });
  });

  group('parseEdgeInsets', () {
    test('all', () {
      expect(parseEdgeInsets({'all': 16}), const EdgeInsets.all(16));
    });
    test('symmetric', () {
      expect(
        parseEdgeInsets({'horizontal': 12, 'vertical': 8}),
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    });
    test('only lados', () {
      expect(
        parseEdgeInsets({'left': 8, 'top': 4}),
        const EdgeInsets.only(left: 8, top: 4),
      );
    });
  });

  group('parseTextStyle', () {
    test('mapeia fontSize/fontWeight/color', () {
      final s = parseTextStyle({
        'fontSize': 16,
        'fontWeight': 'w600',
        'color': '#FFFFFF',
      })!;
      expect(s.fontSize, 16);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.color, const Color(0xFFFFFFFF));
    });
  });
}
