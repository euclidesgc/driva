import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> defaultJson() =>
    jsonDecode(jsonEncode(kDefaultProjectTheme.toJson()))
        as Map<String, dynamic>;

Map<String, dynamic> section(Map<String, dynamic> json, String key) =>
    json[key] as Map<String, dynamic>;

String errorOf(Either<SpecValidationError, ProjectTheme> result) =>
    result.match((error) => error.message, (theme) => fail('esperado Left'));

void main() {
  group('ida e volta', () {
    test('o tema padrão serializado volta igual', () {
      expect(
        parseProjectTheme(kDefaultProjectTheme.toJson()),
        const Right<SpecValidationError, ProjectTheme>(kDefaultProjectTheme),
      );
    });

    test('o JSON decodificado (inteiros como int) volta igual', () {
      expect(
        parseProjectTheme(defaultJson()),
        const Right<SpecValidationError, ProjectTheme>(kDefaultProjectTheme),
      );
    });

    test('fontFamily faz a ida e volta', () {
      final json = defaultJson();
      section(json, 'textStyles')['bodyMedium'] = {
        'fontSize': 14,
        'fontWeight': 'w400',
        'lineHeight': 1.43,
        'letterSpacing': 0.25,
        'fontFamily': 'Inter',
      };

      final theme = parseProjectTheme(json).getOrElse((e) => fail('$e'));

      expect(
        theme.textStyles[ThemeTextStyleName.bodyMedium]!.fontFamily,
        'Inter',
      );
      expect(
        parseProjectTheme(theme.toJson()),
        Right<SpecValidationError, ProjectTheme>(theme),
      );
    });
  });

  group('chaves de topo', () {
    test('chave extra é recusada citando a chave', () {
      final json = defaultJson()..['fonts'] = <String, dynamic>{};

      expect(errorOf(parseProjectTheme(json)), contains('fonts'));
    });

    test('chave faltando é recusada citando a chave', () {
      final json = defaultJson()..remove('radii');

      expect(errorOf(parseProjectTheme(json)), contains('radii'));
    });

    test('grupo que não é objeto é recusado', () {
      final json = defaultJson()..['colors'] = 'primary';

      expect(errorOf(parseProjectTheme(json)), 'colors: esperado um objeto');
    });
  });

  group('nome faltando', () {
    const cases = {
      'colors': ('primary', 'colors: falta o papel "primary"'),
      'textStyles': ('labelSmall', 'textStyles: falta o estilo "labelSmall"'),
      'radii': ('medium', 'radii: falta o passo "medium"'),
      'shadows': ('level5', 'shadows: falta o nível "level5"'),
    };

    for (final MapEntry(key: key, value: (name, message)) in cases.entries) {
      test('$key sem $name é recusado citando o nome', () {
        final json = defaultJson();
        section(json, key).remove(name);

        expect(errorOf(parseProjectTheme(json)), message);
      });
    }
  });

  group('nome desconhecido', () {
    final cases = {
      'colors': ('brand', '#123456', 'colors: papel "brand" desconhecido'),
      'textStyles': (
        'caption',
        section(defaultJson(), 'textStyles')['bodySmall'],
        'textStyles: estilo "caption" desconhecido',
      ),
      'radii': ('huge', 40, 'radii: passo "huge" desconhecido'),
      'shadows': (
        'level6',
        section(defaultJson(), 'shadows')['level5'],
        'shadows: nível "level6" desconhecido',
      ),
    };

    for (final MapEntry(key: key, value: (name, value, message))
        in cases.entries) {
      test('$key com $name é recusado citando o nome', () {
        final json = defaultJson();
        section(json, key)[name] = value;

        expect(errorOf(parseProjectTheme(json)), message);
      });
    }
  });

  group('valor inválido cita o caminho', () {
    test('hex inválido', () {
      final json = defaultJson();
      section(json, 'colors')['primary'] = '6750A4';

      expect(
        errorOf(parseProjectTheme(json)),
        'colors.primary: esperado #RRGGBB ou #AARRGGBB',
      );
    });

    test('hex de cor da sombra inválido', () {
      final json = defaultJson();
      (section(json, 'shadows')['level1'] as Map)['color'] = '#33';

      expect(
        errorOf(parseProjectTheme(json)),
        'shadows.level1.color: esperado #RRGGBB ou #AARRGGBB',
      );
    });

    test('fontSize 0', () {
      final json = defaultJson();
      (section(json, 'textStyles')['bodyMedium'] as Map)['fontSize'] = 0;

      expect(
        errorOf(parseProjectTheme(json)),
        startsWith('textStyles.bodyMedium.fontSize: '),
      );
    });

    test("fontWeight 'w450'", () {
      final json = defaultJson();
      (section(json, 'textStyles')['titleSmall'] as Map)['fontWeight'] = 'w450';

      expect(
        errorOf(parseProjectTheme(json)),
        startsWith('textStyles.titleSmall.fontWeight: '),
      );
    });

    test('raio -1', () {
      final json = defaultJson();
      section(json, 'radii')['small'] = -1;

      expect(errorOf(parseProjectTheme(json)), startsWith('radii.small: '));
    });

    test('blur -1', () {
      final json = defaultJson();
      (section(json, 'shadows')['level2'] as Map)['blur'] = -1;

      expect(
        errorOf(parseProjectTheme(json)),
        startsWith('shadows.level2.blur: '),
      );
    });

    test('estilo que não é objeto', () {
      final json = defaultJson();
      section(json, 'textStyles')['bodyLarge'] = 16;

      expect(
        errorOf(parseProjectTheme(json)),
        'textStyles.bodyLarge: esperado um objeto',
      );
    });

    test('campo faltando ou de tipo errado vira Left, sem exceção', () {
      final missing = defaultJson();
      (section(missing, 'textStyles')['bodyMedium'] as Map).remove('fontSize');
      final wrongType = defaultJson();
      (section(wrongType, 'shadows')['level1'] as Map)['blur'] = '2';
      final nullColor = defaultJson();
      section(nullColor, 'colors')['info'] = null;

      expect(
        errorOf(parseProjectTheme(missing)),
        startsWith('textStyles.bodyMedium.fontSize: '),
      );
      expect(
        errorOf(parseProjectTheme(wrongType)),
        startsWith('shadows.level1.blur: '),
      );
      expect(errorOf(parseProjectTheme(nullColor)), startsWith('colors.info'));
    });

    test('spread e deslocamento negativos são aceitos', () {
      final json = defaultJson();
      (section(json, 'shadows')['level3'] as Map)
        ..['spread'] = -2
        ..['offsetX'] = -1;

      expect(parseProjectTheme(json).isRight(), isTrue);
    });
  });
}
