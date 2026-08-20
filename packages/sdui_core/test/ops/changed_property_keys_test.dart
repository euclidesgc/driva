import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

const SduiNode _emptyNode = SduiNode(id: 'node-1', type: 'text');

void main() {
  group('changedPropertyKeys', () {
    test('dois nós sem propriedade alguma devolve conjunto vazio', () {
      expect(changedPropertyKeys(_emptyNode, _emptyNode), isEmpty);
    });

    test('chave só na base entra no conjunto', () {
      final base = _emptyNode.copyWith(properties: {'text': 'Olá'});
      final candidate = _emptyNode;

      expect(changedPropertyKeys(base, candidate), {'text'});
    });

    test('chave só na candidata entra no conjunto', () {
      final base = _emptyNode;
      final candidate = _emptyNode.copyWith(properties: {'text': 'Olá'});

      expect(changedPropertyKeys(base, candidate), {'text'});
    });

    test('chave presente e igual nos dois lados não entra', () {
      final base = _emptyNode.copyWith(
        properties: {'text': 'Olá', 'color': 'red'},
      );
      final candidate = _emptyNode.copyWith(
        properties: {'text': 'Olá', 'color': 'blue'},
      );

      expect(changedPropertyKeys(base, candidate), {'color'});
    });

    test('valor de mapa aninhado diferente em profundidade entra', () {
      final base = _emptyNode.copyWith(
        properties: {
          'padding': {
            'top': 8,
            'nested': {'left': 4},
          },
        },
      );
      final candidate = _emptyNode.copyWith(
        properties: {
          'padding': {
            'top': 8,
            'nested': {'left': 16},
          },
        },
      );

      expect(changedPropertyKeys(base, candidate), {'padding'});
    });

    test('lista com mesma ordem e valores não entra', () {
      final base = _emptyNode.copyWith(
        properties: {
          'items': ['a', 'b', 'c'],
        },
      );
      final candidate = _emptyNode.copyWith(
        properties: {
          'items': ['a', 'b', 'c'],
        },
      );

      expect(changedPropertyKeys(base, candidate), isEmpty);
    });

    test('lista reordenada entra', () {
      final base = _emptyNode.copyWith(
        properties: {
          'items': ['a', 'b', 'c'],
        },
      );
      final candidate = _emptyNode.copyWith(
        properties: {
          'items': ['b', 'a', 'c'],
        },
      );

      expect(changedPropertyKeys(base, candidate), {'items'});
    });

    test('diferença só em events não entra: a função só olha properties', () {
      final base = _emptyNode.copyWith(
        properties: {'text': 'Olá'},
        events: {
          'onTap': {'action': 'navigate'},
        },
      );
      final candidate = _emptyNode.copyWith(
        properties: {'text': 'Olá'},
        events: {
          'onTap': {'action': 'submit'},
        },
      );

      expect(changedPropertyKeys(base, candidate), isEmpty);
    });

    test('nó sem properties comparado a nó com properties devolve as chaves '
        'da candidata', () {
      final base = _emptyNode;
      final candidate = _emptyNode.copyWith(
        properties: {'text': 'Olá', 'color': 'red'},
      );

      expect(changedPropertyKeys(base, candidate), {'text', 'color'});
    });
  });
}
