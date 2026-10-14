import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

String describe(PropValue value) => switch (value) {
  LiteralPropValue() => 'literal',
  ThemeRefPropValue() => 'theme',
  BoundPropValue() => 'bound',
};

void main() {
  group('igualdade por valor', () {
    test('LiteralPropValue compara o valor, inclusive mapa', () {
      expect(const LiteralPropValue(16), const LiteralPropValue(16));
      expect(
        const LiteralPropValue({'all': 16}),
        const LiteralPropValue({'all': 16}),
      );
      expect(const LiteralPropValue(16), isNot(const LiteralPropValue(8)));
    });

    test('ThemeRefPropValue compara o token', () {
      expect(
        const ThemeRefPropValue('primary'),
        const ThemeRefPropValue('primary'),
      );
      expect(
        const ThemeRefPropValue('primary'),
        isNot(const ThemeRefPropValue('secondary')),
      );
    });

    test('BoundPropValue compara todos os campos', () {
      const base = BoundPropValue(
        source: 'pageParam',
        path: 'user.name',
        fallback: 'Visitante',
      );
      expect(
        base,
        const BoundPropValue(
          source: 'pageParam',
          path: 'user.name',
          fallback: 'Visitante',
        ),
      );
      expect(
        base,
        isNot(
          const BoundPropValue(
            source: 'pageParam',
            path: 'user.name',
            fallback: 'Visitante',
            preview: 'Maria',
          ),
        ),
      );
    });
  });

  test('switch exaustivo cobre as três variantes', () {
    expect(describe(const LiteralPropValue('a')), 'literal');
    expect(describe(const ThemeRefPropValue('primary')), 'theme');
    expect(describe(const BoundPropValue.legacy('x')), 'bound');
  });

  group('toJson', () {
    test('LiteralPropValue devolve o valor cru', () {
      expect(const LiteralPropValue('#6C4CF1').toJson(), '#6C4CF1');
      expect(const LiteralPropValue({'all': 16}).toJson(), {'all': 16});
    });

    test(r'ThemeRefPropValue grava {"$theme": token}', () {
      expect(const ThemeRefPropValue('primary').toJson(), {
        r'$theme': 'primary',
      });
    });

    test('BoundPropValue.legacy grava {{path}}', () {
      const value = BoundPropValue.legacy('x');
      expect(value.isLegacy, isTrue);
      expect(value.source, BindingSourceIds.legacy);
      expect(value.toJson(), '{{x}}');
    });

    test(r'BoundPropValue grava $bind só com as chaves presentes', () {
      final json = const BoundPropValue(
        source: 'pageParam',
        path: 'a',
      ).toJson();

      expect(json, {
        r'$bind': {'source': 'pageParam', 'path': 'a'},
      });
      final bind = (json! as Map)[r'$bind'] as Map;
      for (final key in ['transform', 'fallback', 'preview', 'literal']) {
        expect(bind.containsKey(key), isFalse, reason: key);
      }
    });

    test(r'BoundPropValue completo grava todas as chaves em $bind', () {
      const value = BoundPropValue(
        source: 'pageParam',
        path: 'user.name',
        transform: 'upper',
        fallback: 'Visitante',
        preview: 'Maria',
        literal: 'Olá',
      );

      expect(value.isLegacy, isFalse);
      expect(value.toJson(), {
        r'$bind': {
          'source': 'pageParam',
          'path': 'user.name',
          'transform': 'upper',
          'fallback': 'Visitante',
          'preview': 'Maria',
          'literal': 'Olá',
        },
      });
    });
  });

  group('isTypedForm', () {
    test(r'reconhece só mapa com $theme ou $bind', () {
      expect(PropValue.isTypedForm({r'$theme': 'primary'}), isTrue);
      expect(PropValue.isTypedForm({r'$bind': <String, dynamic>{}}), isTrue);
      expect(PropValue.isTypedForm({r'$foo': 1}), isFalse);
      expect(PropValue.isTypedForm({'all': 16}), isFalse);
      expect(PropValue.isTypedForm('{{x}}'), isFalse);
      expect(PropValue.isTypedForm(null), isFalse);
    });
  });
}
