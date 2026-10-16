import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  test('tem exatamente os 13 tipos do componente', () {
    expect(ComponentParamType.values.map((t) => t.name), [
      'text',
      'integer',
      'decimal',
      'boolean',
      'color',
      'icon',
      'dimension',
      'option',
      'spacing',
      'alignment',
      'action',
      'widgetBuilder',
      'childWidget',
    ]);
  });

  test('isData é falso só para action, widgetBuilder e childWidget', () {
    final special = ComponentParamType.values.where((t) => !t.isData);
    expect(special, [
      ComponentParamType.action,
      ComponentParamType.widgetBuilder,
      ComponentParamType.childWidget,
    ]);
  });

  test('cada tipo tem rótulo em pt-BR', () {
    expect(ComponentParamType.integer.label, 'número inteiro');
    expect(ComponentParamType.childWidget.label, 'widget filho');
    expect(ComponentParamType.values.every((t) => t.label.isNotEmpty), isTrue);
  });

  test('fromName devolve o tipo pelo nome e null para o desconhecido', () {
    expect(ComponentParamType.fromName('color'), ComponentParamType.color);
    expect(ComponentParamType.fromName('any'), isNull);
    expect(ComponentParamType.fromName(3), isNull);
  });

  group('accepts sem lista', () {
    const node = {'id': 'n1', 'type': 'text'};
    final cases = <ComponentParamType, ({Object? accepted, Object? refused})>{
      ComponentParamType.text: (accepted: 'Olá', refused: 3),
      ComponentParamType.integer: (accepted: 3, refused: 1.5),
      ComponentParamType.decimal: (accepted: 1.5, refused: '1.5'),
      ComponentParamType.boolean: (accepted: true, refused: 'true'),
      ComponentParamType.color: (accepted: '#FF0000', refused: 'vermelho'),
      ComponentParamType.icon: (accepted: 'star', refused: 1),
      ComponentParamType.dimension: (accepted: '70%', refused: 'largo'),
      ComponentParamType.option: (accepted: 'a', refused: 'z'),
      ComponentParamType.spacing: (accepted: {'all': 8}, refused: {'all': '8'}),
      ComponentParamType.alignment: (accepted: 'center', refused: 'meio'),
      ComponentParamType.action: (
        accepted: [
          {'action': 'navigate'},
        ],
        refused: {'action': 'navigate'},
      ),
      ComponentParamType.widgetBuilder: (accepted: node, refused: {'id': 'n1'}),
      ComponentParamType.childWidget: (accepted: node, refused: 'text'),
    };

    test('os casos cobrem os 13 tipos', () {
      expect(cases.keys.toSet(), ComponentParamType.values.toSet());
    });

    for (final MapEntry(key: type, :value) in cases.entries) {
      test(
        '${type.name} aceita ${value.accepted} e recusa ${value.refused}',
        () {
          expect(
            type.accepts(value.accepted, isList: false, options: const ['a']),
            isTrue,
          );
          expect(
            type.accepts(value.refused, isList: false, options: const ['a']),
            isFalse,
          );
        },
      );
    }
  });

  group('accepts com lista', () {
    test('valor que não é lista é recusado', () {
      expect(ComponentParamType.text.accepts('Olá', isList: true), isFalse);
    });

    test('lista com todos os itens válidos é aceita', () {
      expect(ComponentParamType.text.accepts(['a', 'b'], isList: true), isTrue);
      expect(ComponentParamType.integer.accepts(<int>[], isList: true), isTrue);
    });

    test('lista com um item inválido é recusada', () {
      expect(ComponentParamType.text.accepts(['a', 2], isList: true), isFalse);
    });

    test('lista de ações exige uma lista de listas de ações', () {
      final actions = [
        {'action': 'navigate'},
      ];
      expect(
        ComponentParamType.action.accepts([actions], isList: true),
        isTrue,
      );
      expect(ComponentParamType.action.accepts(actions, isList: true), isFalse);
    });
  });

  group('regras finas', () {
    test('decimal aceita inteiro e integer recusa decimal', () {
      expect(ComponentParamType.decimal.accepts(3, isList: false), isTrue);
      expect(ComponentParamType.integer.accepts(1.5, isList: false), isFalse);
    });

    test('option recusa String fora de options e aceita a de dentro', () {
      const options = ['pequeno', 'grande'];
      expect(
        ComponentParamType.option.accepts(
          'médio',
          isList: false,
          options: options,
        ),
        isFalse,
      );
      expect(
        ComponentParamType.option.accepts(
          'grande',
          isList: false,
          options: options,
        ),
        isTrue,
      );
    });

    test('color aceita #RRGGBB e #AARRGGBB e recusa outros tamanhos', () {
      expect(
        ComponentParamType.color.accepts('#80FF0000', isList: false),
        isTrue,
      );
      expect(ComponentParamType.color.accepts('#FFF', isList: false), isFalse);
      expect(
        ComponentParamType.color.accepts('FF0000', isList: false),
        isFalse,
      );
    });

    test('spacing recusa chave desconhecida', () {
      expect(
        ComponentParamType.spacing.accepts({
          'all': 8,
          'meio': 2,
        }, isList: false),
        isFalse,
      );
      expect(
        ComponentParamType.spacing.accepts({
          'horizontal': 8,
          'top': 2.5,
        }, isList: false),
        isTrue,
      );
    });

    test('action recusa item sem action ou com action vazia', () {
      expect(
        ComponentParamType.action.accepts([
          {'action': ''},
        ], isList: false),
        isFalse,
      );
      expect(
        ComponentParamType.action.accepts([
          {'params': <String, dynamic>{}},
        ], isList: false),
        isFalse,
      );
    });

    test('alignment aceita o par livre', () {
      expect(
        ComponentParamType.alignment.accepts({
          'x': 0.5,
          'y': -1,
        }, isList: false),
        isTrue,
      );
    });

    test('dimension aceita pixels e inf', () {
      expect(ComponentParamType.dimension.accepts(120, isList: false), isTrue);
      expect(
        ComponentParamType.dimension.accepts('inf', isList: false),
        isTrue,
      );
    });
  });
}
