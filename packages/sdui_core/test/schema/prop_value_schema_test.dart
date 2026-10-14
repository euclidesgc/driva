import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

PropValue parsed(Object? raw) {
  final result = parsePropValue(raw);
  return result.getOrElse((error) => fail('esperado Right, veio $error'));
}

SpecValidationError errorOf(Object? raw, {required String path}) {
  final result = parsePropValue(raw, path: path);
  return result.getLeft().toNullable() ?? fail('esperado Left, veio $result');
}

void main() {
  group('literal', () {
    final literals = <Object?>[
      'olá',
      16,
      1.5,
      true,
      null,
      {'all': 16},
      {r'$foo': 1},
      '{{ }}',
      'olá {{x}}',
    ];

    for (final raw in literals) {
      test('$raw vira LiteralPropValue', () {
        expect(parsed(raw), LiteralPropValue(raw));
      });
    }
  });

  group('legado {{x}}', () {
    test('"{{user.name}}" vira Bound legacy', () {
      final value = parsed('{{user.name}}');

      expect(value, isA<BoundPropValue>());
      final bound = value as BoundPropValue;
      expect(bound.source, 'legacy');
      expect(bound.path, 'user.name');
      expect(bound.isLegacy, isTrue);
    });

    test('"{{ x }}" vira legacy x e grava "{{x}}"', () {
      final value = parsed('{{ x }}');

      expect(value, const BoundPropValue.legacy('x'));
      expect(value.toJson(), '{{x}}');
    });
  });

  group(r'$theme', () {
    test('vira ThemeRefPropValue', () {
      expect(
        parsed({r'$theme': 'primary'}),
        const ThemeRefPropValue('primary'),
      );
    });
  });

  group(r'$bind', () {
    test('mínimo vira BoundPropValue sem opcionais', () {
      expect(
        parsed({
          r'$bind': {'source': 'pageParam', 'path': 'user.name'},
        }),
        const BoundPropValue(source: 'pageParam', path: 'user.name'),
      );
    });

    test('completo preserva todos os campos', () {
      expect(
        parsed({
          r'$bind': {
            'source': 'pageParam',
            'path': 'user.name',
            'transform': 'upper',
            'fallback': 'Visitante',
            'preview': 'Maria',
            'literal': {'all': 16},
          },
        }),
        const BoundPropValue(
          source: 'pageParam',
          path: 'user.name',
          transform: 'upper',
          fallback: 'Visitante',
          preview: 'Maria',
          literal: {'all': 16},
        ),
      );
    });
  });

  group('round-trip', () {
    const values = <PropValue>[
      LiteralPropValue('#6C4CF1'),
      LiteralPropValue({'horizontal': 8, 'vertical': 4}),
      ThemeRefPropValue('primary'),
      BoundPropValue.legacy('user.name'),
      BoundPropValue(
        source: 'pageParam',
        path: 'user.name',
        transform: 'upper',
        fallback: 'Visitante',
        preview: 'Maria',
        literal: 'Olá',
      ),
    ];

    for (final value in values) {
      test('${value.runtimeType} ${value.toJson()}', () {
        expect(parsed(value.toJson()), value);
      });
    }
  });

  group('erros de forma', () {
    const path = 'root.props.data';

    final cases = <String, (Object?, String)>{
      r'$theme com chave extra': (
        {r'$theme': 'primary', 'extra': 1},
        r'$theme não aceita outras chaves (extra)',
      ),
      r'$theme e $bind juntos': (
        {
          r'$theme': 'primary',
          r'$bind': {'source': 'pageParam', 'path': 'a'},
        },
        r'$theme não aceita outras chaves ($bind)',
      ),
      'token vazio': ({r'$theme': ''}, '$path.\$theme'),
      'token que não é texto': ({r'$theme': 1}, '$path.\$theme'),
      r'$bind que não é objeto': (
        {r'$bind': 'pageParam'},
        '$path.\$bind: esperado um objeto',
      ),
      r'$bind com chave desconhecida': (
        {
          r'$bind': {'source': 'pageParam', 'path': 'a', 'foo': 1},
        },
        '$path.\$bind: chave desconhecida "foo"',
      ),
      r'$bind sem source': (
        {
          r'$bind': {'path': 'a'},
        },
        '$path.\$bind',
      ),
      r'$bind com path vazio': (
        {
          r'$bind': {'source': 'pageParam', 'path': ''},
        },
        '$path.\$bind',
      ),
      r'$bind com transform vazio': (
        {
          r'$bind': {'source': 'pageParam', 'path': 'a', 'transform': ''},
        },
        '$path.\$bind',
      ),
      'fallback nulo': (
        {
          r'$bind': {'source': 'pageParam', 'path': 'a', 'fallback': null},
        },
        '$path.\$bind.fallback: esperado um literal JSON',
      ),
      r'preview com $theme': (
        {
          r'$bind': {
            'source': 'pageParam',
            'path': 'a',
            'preview': {r'$theme': 'x'},
          },
        },
        '$path.\$bind.preview: esperado um literal JSON',
      ),
      r'literal com $bind': (
        {
          r'$bind': {
            'source': 'pageParam',
            'path': 'a',
            'literal': {
              r'$bind': {'source': 'pageParam', 'path': 'b'},
            },
          },
        },
        '$path.\$bind.literal: esperado um literal JSON',
      ),
      r'fonte legacy em $bind': (
        {
          r'$bind': {'source': 'legacy', 'path': 'a', 'fallback': 'x'},
        },
        '$path.\$bind.source: fonte "legacy" só vale como {{expressão}}',
      ),
    };

    for (final MapEntry(key: name, value: (raw, expected)) in cases.entries) {
      test(name, () {
        final error = errorOf(raw, path: path);
        expect(error.message, startsWith(path));
        expect(error.message, contains(expected));
      });
    }
  });
}
