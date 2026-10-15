import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> param(
  String name,
  String type, {
  bool isList = false,
  bool required = false,
  Map<String, dynamic> extra = const {},
}) => {
  'name': name,
  'type': type,
  'isList': isList,
  'required': required,
  ...extra,
};

Map<String, dynamic> variable(
  String name,
  String type, {
  Map<String, dynamic> extra = const {},
}) => {'name': name, 'type': type, 'isList': false, ...extra};

String paramsError(Object? raw) => parseComponentParams(raw).match(
  (error) => error.message,
  (params) => fail('esperado Left, veio $params'),
);

String stateError(Object? raw) => parseComponentState(raw).match(
  (error) => error.message,
  (state) => fail('esperado Left, veio $state'),
);

void main() {
  group('parseComponentParams: leitura', () {
    test('lê um parâmetro de cada um dos 13 tipos', () {
      final raw = [
        param('t', 'text', required: true, extra: {'default': 'Olá'}),
        param('i', 'integer', extra: {'default': 3}),
        param('d', 'decimal', extra: {'default': 1.5}),
        param('b', 'boolean', extra: {'default': false}),
        param('c', 'color', extra: {'default': '#FFFFFF'}),
        param('ic', 'icon'),
        param('dim', 'dimension', extra: {'default': '50%'}),
        param(
          'o',
          'option',
          extra: {
            'options': ['p', 'g'],
            'default': 'g',
          },
        ),
        param(
          's',
          'spacing',
          extra: {
            'default': {'all': 8},
          },
        ),
        param('al', 'alignment', extra: {'default': 'center'}),
        param(
          'a',
          'action',
          extra: {
            'params': [param('quantidade', 'integer', required: true)],
          },
        ),
        param('wb', 'widgetBuilder'),
        param(
          'cw',
          'childWidget',
          isList: true,
          extra: {'description': 'Slot livre'},
        ),
      ];

      final params = parseComponentParams(raw).getOrElse((e) => fail('$e'));

      expect(params.map((p) => p.type), ComponentParamType.values);
      expect(params.first.isRequired, isTrue);
      expect(params.first.defaultValue, 'Olá');
      expect(params[7].options, ['p', 'g']);
      expect(params[10].callbackParams, const [
        ComponentParam(
          name: 'quantidade',
          type: ComponentParamType.integer,
          isList: false,
          isRequired: true,
        ),
      ]);
      expect(params.last.isList, isTrue);
      expect(params.last.description, 'Slot livre');
    });

    test('raw nulo vira lista vazia', () {
      expect(parseComponentParams(null).getOrElse((e) => fail('$e')), isEmpty);
    });

    test('toJson do lido devolve o JSON de entrada', () {
      final raw = [
        param('c', 'color', extra: {'default': '#FFFFFF'}),
        param(
          'a',
          'action',
          extra: {
            'params': [param('n', 'integer')],
          },
        ),
      ];

      final params = parseComponentParams(raw).getOrElse((e) => fail('$e'));

      expect([for (final p in params) p.toJson()], raw);
    });
  });

  group('parseComponentParams: erros começam pelo caminho', () {
    test('params que não é lista', () {
      expect(paramsError('x'), startsWith('params:'));
    });

    test('item que não é objeto', () {
      expect(paramsError(['x']), startsWith('params[0]:'));
    });

    test('nome vazio', () {
      expect(paramsError([param('', 'text')]), startsWith('params[0].name:'));
    });

    test('nome repetido', () {
      expect(
        paramsError([param('a', 'text'), param('a', 'integer')]),
        startsWith('params[1].name: nome "a" repetido'),
      );
    });

    for (final type in ['any', 'declared', 'dateTime', 'json']) {
      test('tipo $type', () {
        expect(
          paramsError([param('p', type)]),
          startsWith('params[0].type: tipo "$type" desconhecido'),
        );
      });
    }

    test('isList ausente', () {
      expect(
        paramsError([
          {'name': 'p', 'type': 'text', 'required': true},
        ]),
        startsWith('params[0].isList:'),
      );
    });

    test('required ausente', () {
      expect(
        paramsError([
          {'name': 'p', 'type': 'text', 'isList': false},
        ]),
        startsWith('params[0].required:'),
      );
    });

    test('option sem options', () {
      expect(
        paramsError([param('o', 'option')]),
        startsWith('params[0].options:'),
      );
    });

    test('options num tipo que não é option', () {
      expect(
        paramsError([
          param(
            't',
            'text',
            extra: {
              'options': ['a'],
            },
          ),
        ]),
        startsWith('params[0].options:'),
      );
    });

    test('default fora de options', () {
      expect(
        paramsError([
          param(
            'o',
            'option',
            extra: {
              'options': ['a'],
              'default': 'b',
            },
          ),
        ]),
        'params[0].default: esperado opção',
      );
    });

    test('default incompatível com o tipo', () {
      expect(
        paramsError([
          param('i', 'integer', extra: {'default': '3'}),
        ]),
        'params[0].default: esperado número inteiro',
      );
    });

    test('default de lista que não é lista', () {
      expect(
        paramsError([
          param('i', 'integer', isList: true, extra: {'default': 3}),
        ]),
        'params[0].default: esperado lista de número inteiro',
      );
    });

    test('default num tipo action', () {
      expect(
        paramsError([
          param(
            'a',
            'action',
            extra: {
              'default': [
                {'action': 'navigate'},
              ],
            },
          ),
        ]),
        startsWith('params[0].default:'),
      );
    });

    test('params de action com um tipo especial', () {
      expect(
        paramsError([
          param(
            'a',
            'action',
            extra: {
              'params': [param('w', 'widgetBuilder')],
            },
          ),
        ]),
        startsWith('params[0].params[0].type:'),
      );
    });

    test('params num tipo que não é action', () {
      expect(
        paramsError([
          param(
            't',
            'text',
            extra: {
              'params': [param('n', 'integer')],
            },
          ),
        ]),
        startsWith('params[0].params:'),
      );
    });

    test('description que não é texto', () {
      expect(
        paramsError([
          param('t', 'text', extra: {'description': 3}),
        ]),
        startsWith('params[0].description:'),
      );
    });
  });

  group('parseComponentState', () {
    test('lê variáveis de dado, sem required', () {
      final state = parseComponentState([
        variable('aberto', 'boolean', extra: {'default': false}),
        variable(
          'aba',
          'option',
          extra: {
            'options': ['a', 'b'],
          },
        ),
      ]).getOrElse((e) => fail('$e'));

      expect(state, const [
        ComponentStateVariable(
          name: 'aberto',
          type: ComponentParamType.boolean,
          isList: false,
          defaultValue: false,
        ),
        ComponentStateVariable(
          name: 'aba',
          type: ComponentParamType.option,
          isList: false,
          options: ['a', 'b'],
        ),
      ]);
    });

    test('raw nulo vira lista vazia', () {
      expect(parseComponentState(null).getOrElse((e) => fail('$e')), isEmpty);
    });

    for (final type in ['action', 'widgetBuilder', 'childWidget']) {
      test('variável com tipo especial $type', () {
        expect(
          stateError([variable('v', type)]),
          startsWith('state[0].type:'),
        );
      });
    }

    test('nome repetido', () {
      expect(
        stateError([variable('v', 'text'), variable('v', 'text')]),
        startsWith('state[1].name:'),
      );
    });

    test('default incompatível', () {
      expect(
        stateError([
          variable('v', 'boolean', extra: {'default': 'sim'}),
        ]),
        'state[0].default: esperado verdadeiro ou falso',
      );
    });
  });
}
