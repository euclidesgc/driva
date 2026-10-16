import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

PropField _field(
  String key, {
  VisibilityCondition? visibleWhen,
  Object? defaultValue,
}) => PropField(
  key: key,
  kind: FieldKind.string,
  label: key,
  group: FieldGroups.content,
  defaultValue: defaultValue,
  visibleWhen: visibleWhen,
);

WidgetDescriptor _descriptor(List<PropField> fields) => WidgetDescriptor(
  type: 'probe',
  label: 'Probe',
  iconName: 'probe',
  category: WidgetCategories.basics,
  slot: SlotKind.none,
  fields: fields,
);

void main() {
  final plain = _descriptor([_field('a'), _field('b')]);

  bool eval(VisibilityCondition c, Map<String, dynamic> props) =>
      FieldVisibility.evaluate(c, props, plain);

  group('FieldVisibility.evaluate', () {
    test('PropEquals compara com ==', () {
      expect(eval(const PropEquals('a', 1), {'a': 1}), isTrue);
      expect(eval(const PropEquals('a', 1), {'a': 2}), isFalse);
      expect(eval(const PropEquals('a', 1), {'a': 1.0}), isTrue);
    });

    test('PropNotEquals nega a igualdade', () {
      expect(eval(const PropNotEquals('a', 'x'), {'a': 'y'}), isTrue);
      expect(eval(const PropNotEquals('a', 'x'), {'a': 'x'}), isFalse);
    });

    test('PropIn procura o valor na lista', () {
      const condition = PropIn('a', ['x', 'y']);

      expect(eval(condition, {'a': 'y'}), isTrue);
      expect(eval(condition, {'a': 'z'}), isFalse);
    });

    test('AllOf exige todas e AnyOf aceita qualquer uma', () {
      const all = AllOf([PropEquals('a', 1), PropEquals('b', 2)]);
      const any = AnyOf([PropEquals('a', 1), PropEquals('b', 2)]);

      expect(eval(all, {'a': 1, 'b': 2}), isTrue);
      expect(eval(all, {'a': 1, 'b': 3}), isFalse);
      expect(eval(any, {'a': 0, 'b': 2}), isTrue);
      expect(eval(any, {'a': 0, 'b': 3}), isFalse);
    });

    test('lista vazia: AllOf é verdadeiro e AnyOf é falso', () {
      expect(eval(const AllOf([]), {}), isTrue);
      expect(eval(const AnyOf([]), {}), isFalse);
    });

    test('condição aninhada AllOf([AnyOf([a==1, a==2]), b!=x])', () {
      const condition = AllOf([
        AnyOf([PropEquals('a', 1), PropEquals('a', 2)]),
        PropNotEquals('b', 'x'),
      ]);

      expect(eval(condition, {'a': 2, 'b': 'y'}), isTrue);
      expect(eval(condition, {'a': 3, 'b': 'y'}), isFalse);
      expect(eval(condition, {'a': 1, 'b': 'x'}), isFalse);
    });

    test('prop ausente lê o default do descriptor', () {
      final off = _descriptor([_field('flag', defaultValue: false)]);
      final on = _descriptor([_field('flag', defaultValue: true)]);
      const condition = PropEquals('flag', true);

      expect(FieldVisibility.evaluate(condition, {}, off), isFalse);
      expect(FieldVisibility.evaluate(condition, {}, on), isTrue);
    });

    test('chave presente com null também cai no default', () {
      final on = _descriptor([_field('flag', defaultValue: true)]);

      expect(
        FieldVisibility.evaluate(const PropEquals('flag', true), {
          'flag': null,
        }, on),
        isTrue,
      );
    });

    test('prop ausente e sem default lê null e não lança', () {
      expect(eval(const PropEquals('a', true), {}), isFalse);
      expect(eval(const PropNotEquals('a', true), {}), isTrue);
    });

    test('prop que o descriptor não declara fica indeterminada', () {
      expect(eval(const PropEquals('inexistente', 1), {}), isTrue);
      expect(eval(const PropNotEquals('inexistente', 1), {}), isTrue);
      expect(eval(const PropIn('inexistente', [1]), {}), isTrue);
    });

    group('indeterminateKeys', () {
      bool evalWith(VisibilityCondition c, Map<String, dynamic> props) =>
          FieldVisibility.evaluate(
            c,
            props,
            plain,
            indeterminateKeys: const {'a'},
          );

      test('a chave indeterminada deixa a folha verdadeira', () {
        expect(evalWith(const PropEquals('a', 1), {'a': 2}), isTrue);
        expect(evalWith(const PropNotEquals('a', 1), {'a': 1}), isTrue);
        expect(evalWith(const PropIn('a', [1]), {}), isTrue);
      });

      test('vale dentro de AllOf e AnyOf, sem afetar as outras chaves', () {
        expect(
          evalWith(const AllOf([PropEquals('a', 1), PropEquals('b', 2)]), {
            'b': 2,
          }),
          isTrue,
        );
        expect(
          evalWith(const AllOf([PropEquals('a', 1), PropEquals('b', 2)]), {
            'b': 3,
          }),
          isFalse,
        );
        expect(
          evalWith(const AnyOf([PropEquals('b', 2), PropEquals('a', 1)]), {
            'b': 3,
          }),
          isTrue,
        );
      });
    });

    group('valor indeterminado deixa o campo visível', () {
      final indeterminados = <String, Object>{
        'binding': '{{user.name}}',
        r'$bind': {r'$bind': 'user.name'},
        r'$theme': {r'$theme': 'colors.primary'},
      };

      for (final entry in indeterminados.entries) {
        final props = {'a': entry.value};

        test('${entry.key} em ==, != e in', () {
          expect(eval(const PropEquals('a', 1), props), isTrue);
          expect(eval(const PropNotEquals('a', 1), props), isTrue);
          expect(eval(const PropIn('a', [1, 2]), props), isTrue);
        });

        test('${entry.key} dentro de AllOf e AnyOf', () {
          expect(
            eval(const AllOf([PropEquals('a', 1), PropEquals('b', 2)]), {
              ...props,
              'b': 2,
            }),
            isTrue,
          );
          expect(
            eval(const AnyOf([PropEquals('a', 1), PropEquals('b', 2)]), {
              ...props,
              'b': 3,
            }),
            isTrue,
          );
        });
      }

      test('irmã determinadamente falsa num AllOf ainda esconde', () {
        expect(
          eval(const AllOf([PropEquals('a', 1), PropEquals('b', 2)]), {
            'a': '{{x}}',
            'b': 3,
          }),
          isFalse,
        );
      });
    });
  });

  group('FieldVisibility.isVisible', () {
    test('campo sem visibleWhen fica visível', () {
      final field = _field('a');

      expect(
        FieldVisibility.isVisible(field, {}, _descriptor([field])),
        isTrue,
      );
    });

    test('campo com visibleWhen segue a condição', () {
      final control = _field('flag', defaultValue: false);
      final dependent = _field(
        'color',
        visibleWhen: const PropEquals('flag', true),
      );
      final descriptor = _descriptor([control, dependent]);

      expect(FieldVisibility.isVisible(dependent, {}, descriptor), isFalse);
      expect(
        FieldVisibility.isVisible(dependent, {'flag': true}, descriptor),
        isTrue,
      );
    });

    test('repassa indeterminateKeys para a condição', () {
      final control = _field('flag', defaultValue: false);
      final dependent = _field(
        'color',
        visibleWhen: const PropEquals('flag', true),
      );
      final descriptor = _descriptor([control, dependent]);

      expect(
        FieldVisibility.isVisible(
          dependent,
          {},
          descriptor,
          indeterminateKeys: const {'flag'},
        ),
        isTrue,
      );
    });
  });

  group('FieldVisibility.problemsIn', () {
    test('devolve vazio num descriptor válido', () {
      final descriptor = _descriptor([
        _field('flag'),
        _field('color', visibleWhen: const PropEquals('flag', true)),
        _field(
          'size',
          visibleWhen: const AllOf([
            PropEquals('flag', true),
            AnyOf([
              PropIn('color', ['red']),
            ]),
          ]),
        ),
      ]);

      expect(FieldVisibility.problemsIn(descriptor), isEmpty);
    });

    test('acusa a prop inexistente', () {
      final descriptor = _descriptor([
        _field('color', visibleWhen: const PropEquals('fantasma', true)),
      ]);

      final problems = FieldVisibility.problemsIn(descriptor);

      expect(problems, hasLength(1));
      expect(problems.single, contains('fantasma'));
    });

    test('acusa a auto-referência', () {
      final descriptor = _descriptor([
        _field('color', visibleWhen: const PropEquals('color', 'red')),
      ]);

      final problems = FieldVisibility.problemsIn(descriptor);

      expect(problems, hasLength(1));
      expect(problems.single, contains('próprio campo'));
    });

    test('acusa AllOf ou AnyOf sem condições, mesmo aninhado', () {
      final descriptor = _descriptor([
        _field('flag'),
        _field('color', visibleWhen: const AnyOf([])),
        _field(
          'size',
          visibleWhen: const AllOf([
            PropEquals('flag', true),
            AllOf([]),
          ]),
        ),
      ]);

      final problems = FieldVisibility.problemsIn(descriptor);

      expect(problems, hasLength(2));
      expect(problems, everyElement(contains('sem condições')));
    });
  });
}
