import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentParam.toJson', () {
    test('usa as chaves required e default', () {
      const param = ComponentParam(
        name: 'corDeFundo',
        type: ComponentParamType.color,
        isList: false,
        isRequired: false,
        defaultValue: '#FFFFFF',
        description: 'Cor do card',
      );

      expect(param.toJson(), {
        'name': 'corDeFundo',
        'type': 'color',
        'isList': false,
        'required': false,
        'default': '#FFFFFF',
        'description': 'Cor do card',
      });
    });

    test('omite default, description, options e params ausentes', () {
      const param = ComponentParam(
        name: 'titulo',
        type: ComponentParamType.text,
        isList: false,
        isRequired: true,
      );

      expect(param.toJson(), {
        'name': 'titulo',
        'type': 'text',
        'isList': false,
        'required': true,
      });
    });

    test('grava options e os parâmetros do callback em params', () {
      const param = ComponentParam(
        name: 'aoTocar',
        type: ComponentParamType.action,
        isList: false,
        isRequired: false,
        callbackParams: [
          ComponentParam(
            name: 'quantidade',
            type: ComponentParamType.integer,
            isList: false,
            isRequired: true,
          ),
        ],
      );
      const sized = ComponentParam(
        name: 'tamanho',
        type: ComponentParamType.option,
        isList: false,
        isRequired: false,
        options: ['p', 'g'],
      );

      expect(param.toJson()['params'], [
        {
          'name': 'quantidade',
          'type': 'integer',
          'isList': false,
          'required': true,
        },
      ]);
      expect(sized.toJson()['options'], ['p', 'g']);
    });

    test('default false é gravado', () {
      const param = ComponentParam(
        name: 'aberto',
        type: ComponentParamType.boolean,
        isList: false,
        isRequired: false,
        defaultValue: false,
      );

      expect(param.toJson()['default'], isFalse);
    });

    test('igualdade por valor', () {
      const a = ComponentParam(
        name: 'p',
        type: ComponentParamType.text,
        isList: false,
        isRequired: true,
      );
      const b = ComponentParam(
        name: 'p',
        type: ComponentParamType.text,
        isList: true,
        isRequired: true,
      );

      expect(
        a,
        const ComponentParam(
          name: 'p',
          type: ComponentParamType.text,
          isList: false,
          isRequired: true,
        ),
      );
      expect(a, isNot(b));
    });
  });

  group('ComponentStateVariable.toJson', () {
    test('grava sem required nem params e omite o ausente', () {
      const variable = ComponentStateVariable(
        name: 'aberto',
        type: ComponentParamType.boolean,
        isList: false,
        defaultValue: false,
      );

      expect(variable.toJson(), {
        'name': 'aberto',
        'type': 'boolean',
        'isList': false,
        'default': false,
      });
    });

    test('grava description e options quando presentes', () {
      const variable = ComponentStateVariable(
        name: 'aba',
        type: ComponentParamType.option,
        isList: false,
        description: 'Aba aberta',
        options: ['a', 'b'],
      );

      expect(variable.toJson(), {
        'name': 'aba',
        'type': 'option',
        'isList': false,
        'description': 'Aba aberta',
        'options': ['a', 'b'],
      });
    });
  });

  group('ComponentInstance', () {
    SduiNode instance(Map<String, dynamic> props) =>
        SduiNode(id: 'i1', type: 'component', properties: props);

    test('reconhece o nó de instância pelo tipo', () {
      expect(ComponentInstance.isInstance(instance(const {})), isTrue);
      expect(
        ComponentInstance.isInstance(const SduiNode(id: 't', type: 'text')),
        isFalse,
      );
    });

    test('componentIdOf devolve o id não vazio', () {
      expect(
        ComponentInstance.componentIdOf(instance(const {'componentId': 'c1'})),
        'c1',
      );
    });

    test('componentIdOf devolve null para ausente, vazio e não texto', () {
      expect(ComponentInstance.componentIdOf(instance(const {})), isNull);
      expect(
        ComponentInstance.componentIdOf(instance(const {'componentId': ''})),
        isNull,
      );
      expect(
        ComponentInstance.componentIdOf(instance(const {'componentId': 3})),
        isNull,
      );
    });

    test('argsOf devolve os args ou {} sem args', () {
      expect(ComponentInstance.argsOf(instance(const {})), isEmpty);
      expect(ComponentInstance.argsOf(instance(const {'args': 'x'})), isEmpty);
      expect(
        ComponentInstance.argsOf(
          instance(const {
            'args': {'titulo': 'Olá'},
          }),
        ),
        {'titulo': 'Olá'},
      );
    });
  });
}
