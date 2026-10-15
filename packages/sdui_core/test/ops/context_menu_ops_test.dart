import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  const text = SduiNode(id: 'a', type: 'text');
  const root = SduiNode(
    id: 'root',
    type: 'column',
    children: [
      text,
      SduiNode(id: 'b', type: 'text'),
    ],
  );

  bool isValid(SduiNode node) => parseContentSpec({
    'specVersion': 1,
    'kind': 'content',
    'id': 'c',
    'name': 'n',
    'slug': 's',
    'root': node.toJson(),
  }).isRight();

  group('unwrapNode', () {
    test('desfaz o wrapNode devolvendo a árvore original', () {
      final wrapped = wrapNode(root, 'a', 'row', newId: 'w')!;

      expect(unwrapNode(wrapped, 'w'), root);
    });

    test('vários filhos entram no lugar do wrapper, em ordem', () {
      const inner = SduiNode(
        id: 'w',
        type: 'column',
        children: [
          SduiNode(id: 'x', type: 'text'),
          SduiNode(id: 'y', type: 'text'),
        ],
      );
      const tree = SduiNode(
        id: 'root',
        type: 'column',
        children: [text, inner],
      );

      final result = unwrapNode(tree, 'w')!;

      expect([for (final c in result.children) c.id], ['a', 'x', 'y']);
      expect(isValid(result), isTrue);
    });

    test('recusa raiz, folha e N filhos em slot único', () {
      const two = SduiNode(
        id: 'w',
        type: 'column',
        children: [
          SduiNode(id: 'x', type: 'text'),
          SduiNode(id: 'y', type: 'text'),
        ],
      );
      const tree = SduiNode(id: 'c', type: 'container', child: two);

      expect(unwrapNode(root, 'root'), isNull);
      expect(unwrapNode(root, 'a'), isNull);
      expect(unwrapNode(tree, 'w'), isNull);
    });
  });

  group('replaceNode', () {
    test('column vira row preservando filhos e id', () {
      final result = replaceNode(root, 'root', 'row')!;

      expect(result.type, 'row');
      expect(result.id, 'root');
      expect(result.children, root.children);
      expect(isValid(result), isTrue);
    });

    test('descarta props que o novo tipo não conhece', () {
      const tree = SduiNode(
        id: 'root',
        type: 'column',
        properties: {'spacing': 4.0},
        children: [text],
      );

      expect(replaceNode(tree, 'root', 'stack')!.properties, isEmpty);
    });

    test('descarta os gatilhos que o novo tipo não declara', () {
      const step = {'action': 'navigateBack'};
      const tree = SduiNode(
        id: 'root',
        type: 'column',
        children: [
          SduiNode(
            id: 'btn',
            type: 'button',
            properties: {'label': 'Ok'},
            events: {
              'onPressed': [step],
              'onLongPress': [step],
            },
          ),
        ],
      );

      final result = replaceNode(tree, 'btn', 'text')!;

      expect(findNode(result, 'btn')!.events, {
        'onLongPress': [step],
      });
    });

    test('recusa quando os filhos não cabem', () {
      expect(replaceNode(root, 'root', 'text'), isNull);
      expect(replaceNode(root, 'root', 'container'), isNull);
      expect(replaceNode(root, 'root', 'column'), isNull);
    });
  });

  group('copyStyle / pasteStyle', () {
    const styled = SduiNode(
      id: 'root',
      type: 'column',
      children: [
        SduiNode(
          id: 'a',
          type: 'text',
          properties: {'data': 'oi', 'color': '#FF0000', 'fontSize': 20.0},
        ),
        SduiNode(id: 'b', type: 'text', properties: {'data': 'tchau'}),
      ],
    );

    test('copyStyle leva só props isStyle', () {
      final style = copyStyle(styled, 'a')!;

      expect(style['color'], '#FF0000');
      expect(style['fontSize'], 20.0);
      expect(style.containsKey('data'), isFalse);
    });

    test('pasteStyle aplica só chaves de estilo do tipo alvo', () {
      final result = pasteStyle(styled, 'b', {
        'color': '#FF0000',
        'data': 'invasor',
        'inexistente': 1,
      })!;
      final b = findNode(result, 'b')!;

      expect(b.properties['color'], '#FF0000');
      expect(b.properties['data'], 'tchau');
      expect(b.properties.containsKey('inexistente'), isFalse);
      expect(isValid(result), isTrue);
    });

    test('pasteStyle sem chave aplicável devolve null', () {
      expect(pasteStyle(styled, 'b', {'data': 'x'}), isNull);
    });
  });
}
