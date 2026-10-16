import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart' show resolveThemeTextStyle;
import 'package:sdui_flutter/src/parsing/theme_resolvers.dart'
    show resolveColor;

void main() {
  const theme = kDefaultProjectTheme;

  group('resolveColor', () {
    test('hex literal sai como hoje', () {
      expect(resolveColor('#112233', theme), const Color(0xFF112233));
      expect(resolveColor('#80112233', theme), const Color(0x80112233));
    });

    test('papel conhecido sai com a cor do tema', () {
      expect(
        resolveColor({r'$theme': 'primary'}, theme),
        const Color(0xFF6750A4),
      );
      expect(
        resolveColor({r'$theme': 'primaryText'}, theme),
        const Color(0xFF1D1B20),
      );
    });

    test('papel desconhecido sai null, como prop ausente', () {
      expect(resolveColor({r'$theme': 'brand'}, theme), isNull);
    });

    test(r'$bind sai null', () {
      expect(
        resolveColor({
          r'$bind': {'source': 'pageParam', 'path': 'cor'},
        }, theme),
        isNull,
      );
    });

    test('null sai null', () {
      expect(resolveColor(null, theme), isNull);
    });

    test('papel ausente num tema montado à mão sai null', () {
      const partial = ProjectTheme(
        colors: {},
        textStyles: {},
        radii: {},
        shadows: {},
      );

      expect(resolveColor({r'$theme': 'primary'}, partial), isNull);
    });
  });

  group('resolveThemeTextStyle', () {
    test('bodyMedium do tema padrão', () {
      final style = resolveThemeTextStyle('bodyMedium', theme)!;

      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.height, 1.43);
      expect(style.letterSpacing, 0.25);
      expect(style.fontFamily, isNull);
    });

    test('estilo com fontFamily devolve a família', () {
      final withFamily = ProjectTheme(
        colors: theme.colors,
        textStyles: {
          ...theme.textStyles,
          ThemeTextStyleName.titleSmall: const ThemeTextStyle(
            fontSize: 14,
            fontWeight: 'w600',
            lineHeight: 1.4,
            letterSpacing: 0.1,
            fontFamily: 'Inter',
          ),
        },
        radii: theme.radii,
        shadows: theme.shadows,
      );

      final style = resolveThemeTextStyle('titleSmall', withFamily)!;

      expect(style.fontFamily, 'Inter');
      expect(style.fontWeight, FontWeight.w600);
    });

    test('nome desconhecido devolve null', () {
      expect(resolveThemeTextStyle('foo', theme), isNull);
    });
  });
}
