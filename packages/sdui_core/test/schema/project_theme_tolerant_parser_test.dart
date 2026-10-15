import 'dart:convert';

import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> defaultJson() =>
    jsonDecode(jsonEncode(kDefaultProjectTheme.toJson()))
        as Map<String, dynamic>;

Map<String, dynamic> section(Map<String, dynamic> json, String key) =>
    json[key] as Map<String, dynamic>;

Map<String, dynamic> customJson() {
  final json = defaultJson();
  section(json, 'colors')['primary'] = '#FF0000';
  section(json, 'colors')['info'] = '#80112233';
  section(json, 'textStyles')['bodyMedium'] = {
    'fontSize': 20,
    'fontWeight': 'w700',
    'lineHeight': 1.5,
    'letterSpacing': 0.5,
    'fontFamily': 'Inter',
  };
  section(json, 'radii')['medium'] = 18;
  section(json, 'shadows')['level2'] = {
    'color': '#40000000',
    'offsetX': 1,
    'offsetY': 3,
    'blur': 7,
    'spread': 2,
  };
  return json;
}

void main() {
  group('entrada que não é objeto', () {
    for (final input in <Object?>['abc', <Object?>[], null, 1]) {
      test('${jsonEncode(input)} dá o tema padrão', () {
        expect(parseProjectThemeTolerant(input), kDefaultProjectTheme);
      });
    }
  });

  group('chaves', () {
    test('papel novo é ignorado e o válido é lido', () {
      final theme = parseProjectThemeTolerant({
        'colors': {'brandNew': '#123456', 'primary': '#FF0000'},
      });

      expect(theme.colors[ThemeColorRole.primary], '#FF0000');
      expect(theme.colors.containsKey(ThemeColorRole.secondary), isTrue);
      expect(
        {...theme.colors}..remove(ThemeColorRole.primary),
        {...kDefaultProjectTheme.colors}..remove(ThemeColorRole.primary),
      );
      expect(theme.textStyles, kDefaultProjectTheme.textStyles);
      expect(theme.radii, kDefaultProjectTheme.radii);
      expect(theme.shadows, kDefaultProjectTheme.shadows);
    });

    test('chave de topo desconhecida é ignorada', () {
      final json = defaultJson()..['extra'] = {'a': 1};

      expect(parseProjectThemeTolerant(json), kDefaultProjectTheme);
    });

    test('grupo ausente vem inteiro do padrão', () {
      final json = customJson()..remove('radii');

      final theme = parseProjectThemeTolerant(json);

      expect(theme.radii, kDefaultProjectTheme.radii);
      expect(theme.colors[ThemeColorRole.primary], '#FF0000');
    });

    test('item ausente vem do padrão', () {
      final json = customJson();
      section(json, 'colors').remove('secondary');

      final theme = parseProjectThemeTolerant(json);

      expect(
        theme.colors[ThemeColorRole.secondary],
        kDefaultProjectTheme.colors[ThemeColorRole.secondary],
      );
      expect(theme.colors[ThemeColorRole.primary], '#FF0000');
    });
  });

  group('item inválido volta ao padrão', () {
    test('cor que não é hex', () {
      final json = defaultJson();
      section(json, 'colors')['secondary'] = 'azul';

      final theme = parseProjectThemeTolerant(json);

      expect(
        theme.colors[ThemeColorRole.secondary],
        kDefaultProjectTheme.colors[ThemeColorRole.secondary],
      );
    });

    test('estilo de texto com fontSize inválido volta inteiro', () {
      final json = customJson();
      section(json, 'textStyles')['bodyMedium'] = {
        'fontSize': 'grande',
        'fontWeight': 'w700',
        'lineHeight': 1.5,
        'letterSpacing': 0.5,
        'fontFamily': 'Inter',
      };
      section(json, 'textStyles')['bodySmall'] = {
        'fontSize': 11,
        'fontWeight': 'w300',
        'lineHeight': 1.2,
        'letterSpacing': 0.1,
      };

      final theme = parseProjectThemeTolerant(json);

      expect(
        theme.textStyles[ThemeTextStyleName.bodyMedium],
        kDefaultProjectTheme.textStyles[ThemeTextStyleName.bodyMedium],
      );
      expect(
        theme.textStyles[ThemeTextStyleName.bodySmall]!.fontSize,
        11,
      );
    });

    test('estilo de texto que não é objeto volta ao padrão', () {
      final json = defaultJson();
      section(json, 'textStyles')['bodyMedium'] = 'grande';

      expect(parseProjectThemeTolerant(json), kDefaultProjectTheme);
    });

    test('sombra com blur negativo volta inteira', () {
      final json = defaultJson();
      section(json, 'shadows')['level2'] = {
        'color': '#40000000',
        'offsetX': 1,
        'offsetY': 3,
        'blur': -1,
        'spread': 2,
      };

      final theme = parseProjectThemeTolerant(json);

      expect(
        theme.shadows[ThemeShadowLevel.level2],
        kDefaultProjectTheme.shadows[ThemeShadowLevel.level2],
      );
    });

    test('raio negativo volta ao padrão', () {
      final json = defaultJson();
      section(json, 'radii')['medium'] = -4;

      expect(parseProjectThemeTolerant(json), kDefaultProjectTheme);
    });

    test('grupo que é lista vem inteiro do padrão', () {
      final json = customJson()..['radii'] = [1, 2, 3];

      final theme = parseProjectThemeTolerant(json);

      expect(theme.radii, kDefaultProjectTheme.radii);
      expect(theme.colors[ThemeColorRole.primary], '#FF0000');
    });
  });

  group('tema válido', () {
    test('o tema padrão serializado volta igual', () {
      expect(
        parseProjectThemeTolerant(kDefaultProjectTheme.toJson()),
        kDefaultProjectTheme,
      );
    });

    test('o JSON decodificado (inteiros como int) volta igual', () {
      expect(parseProjectThemeTolerant(defaultJson()), kDefaultProjectTheme);
    });

    test('um tema completo e não padrão é igual ao do parse estrito', () {
      final json = customJson();

      final strict = parseProjectTheme(json).getOrElse((e) => fail('$e'));

      expect(strict, isNot(kDefaultProjectTheme));
      expect(parseProjectThemeTolerant(json), strict);
    });
  });
}
