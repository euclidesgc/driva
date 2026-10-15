import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> textNode(Object? data) => {
    'id': 'n1',
    'type': 'text',
    'props': {'data': data},
  };

  const themed = {r'$theme': 'primary'};

  Map<String, dynamic> themedColorTextNode() => {
    'id': 'n1',
    'type': 'text',
    'props': {'data': 'oi', 'color': themed},
  };

  group('parseNode e specVersion', () {
    test(r'sem specVersion, recusa $theme como a versão mais antiga', () {
      final result = parseNode(textNode(themed));

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()!.message,
        startsWith('root.props.data: '),
      );
      expect(
        result.getLeft().toNullable()!.message,
        contains('specVersion $kTypedPropValuesSpecVersion'),
      );
    });

    test(r'com specVersion 2, aceita $theme e guarda o mapa cru', () {
      final result = parseNode(
        themedColorTextNode(),
        specVersion: kTypedPropValuesSpecVersion,
      );

      final node = result.getRight().toNullable();
      expect(node, isNotNull, reason: result.toString());
      expect(node!.properties['color'], themed);
    });

    test('repassa specVersion aos filhos', () {
      final json = <String, dynamic>{
        'id': 'c1',
        'type': 'column',
        'children': [themedColorTextNode()],
      };

      expect(parseNode(json).isLeft(), isTrue);
      expect(
        parseNode(json, specVersion: kTypedPropValuesSpecVersion).isRight(),
        isTrue,
      );
    });
  });

  group('nó de instância de componente', () {
    const paramBind = {
      r'$bind': {'source': 'componentParam', 'path': 'p'},
    };

    Map<String, dynamic> instance(Map<String, dynamic> props) => {
      'id': 'i1',
      'type': 'component',
      'props': props,
    };

    String errorOf(
      Map<String, dynamic> json, {
      int specVersion = 1,
      BindingContext context = BindingContext.page,
    }) => parseNode(json, specVersion: specVersion, context: context).match(
      (error) => error.message,
      (node) => fail('esperado Left, veio $node'),
    );

    test('com componentId e args é lido no modo estrito', () {
      final result = parseNode(
        instance({
          'componentId': 'c1',
          'args': {'titulo': 'Olá'},
        }),
      );

      final node = result.getOrElse((e) => fail('$e'));
      expect(node.type, 'component');
      expect(ComponentInstance.componentIdOf(node), 'c1');
      expect(ComponentInstance.argsOf(node), {'titulo': 'Olá'});
    });

    test('sem args é lido', () {
      expect(parseNode(instance({'componentId': 'c1'})).isRight(), isTrue);
    });

    test('componentId ausente, vazio ou não texto reprova', () {
      for (final props in <Map<String, dynamic>>[
        {},
        {'componentId': ''},
        {'componentId': 3},
      ]) {
        expect(
          errorOf(instance(props)),
          startsWith('root.props.componentId:'),
        );
      }
    });

    test('instância sem props reprova pelo componentId', () {
      expect(
        errorOf({'id': 'i1', 'type': 'component'}),
        startsWith('root.props.componentId:'),
      );
    });

    test('args que não é objeto reprova', () {
      expect(
        errorOf(instance({'componentId': 'c1', 'args': 'x'})),
        startsWith('root.props.args:'),
      );
    });

    test('instância é folha: child e children reprovam', () {
      final props = {'componentId': 'c1'};
      expect(
        errorOf({...instance(props), 'child': textNode('a')}),
        contains('é folha'),
      );
      expect(
        errorOf({
          ...instance(props),
          'children': [textNode('a')],
        }),
        contains('é folha'),
      );
    });

    test(r'arg $bind componentParam exige o contexto de componente', () {
      final json = instance({
        'componentId': 'c1',
        'args': {'titulo': paramBind},
      });

      expect(
        errorOf(json, specVersion: 2),
        startsWith(r'root.props.args.titulo.$bind.source:'),
      );
      expect(
        parseNode(
          json,
          specVersion: 2,
          context: BindingContext.component,
        ).isRight(),
        isTrue,
      );
    });

    test(r'arg $bind exige specVersion 2', () {
      final json = instance({
        'componentId': 'c1',
        'args': {'titulo': paramBind},
      });

      expect(
        errorOf(json, context: BindingContext.component),
        startsWith('root.props.args.titulo:'),
      );
    });

    test('o contexto chega aos filhos', () {
      final column = {
        'id': 'col',
        'type': 'column',
        'children': [
          textNode({
            r'$bind': {'source': 'componentParam', 'path': 'p', 'fallback': ''},
          }),
        ],
      };

      expect(
        parseNode(
          column,
          specVersion: 2,
          context: BindingContext.component,
        ).isRight(),
        isTrue,
      );
      expect(
        errorOf(column, specVersion: 2),
        startsWith(r'root.children[0].props.data.$bind.source:'),
      );
    });

    test('instância dentro de um filho é lida', () {
      final column = {
        'id': 'col',
        'type': 'column',
        'children': [
          instance({'componentId': 'c1'}),
        ],
      };

      expect(parseNode(column).isRight(), isTrue);
    });
  });
}
