import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  // Árvore base:
  // root(column) ── a(text), b(container ── b1(text)), c(row ── c1(icon))
  const b1 = SduiNode(id: 'b1', type: 'text');
  const c1 = SduiNode(id: 'c1', type: 'icon');
  const root = SduiNode(
    id: 'root',
    type: 'column',
    children: [
      SduiNode(id: 'a', type: 'text'),
      SduiNode(id: 'b', type: 'container', child: b1),
      SduiNode(id: 'c', type: 'row', children: [c1]),
    ],
  );

  group('findNode / findParent', () {
    test('acha nó em qualquer profundidade', () {
      expect(findNode(root, 'root')?.id, 'root');
      expect(findNode(root, 'b1')?.type, 'text');
      expect(findNode(root, 'c1')?.type, 'icon');
      expect(findNode(root, 'nao-existe'), isNull);
    });

    test('acha o pai tanto de child quanto de children', () {
      expect(findParent(root, 'a')?.id, 'root');
      expect(findParent(root, 'b1')?.id, 'b');
      expect(findParent(root, 'c1')?.id, 'c');
      expect(findParent(root, 'root'), isNull);
    });
  });

  group('insertChild', () {
    test('insere na posição pedida', () {
      const novo = SduiNode(id: 'x', type: 'divider');

      final result = insertChild(root, 'root', 1, novo);

      expect(result.children.map((n) => n.id), ['a', 'x', 'b', 'c']);
      expect(root.children, hasLength(3), reason: 'original imutável');
    });

    test('clampa índice fora do intervalo', () {
      const novo = SduiNode(id: 'x', type: 'divider');

      final result = insertChild(root, 'root', 99, novo);

      expect(result.children.last.id, 'x');
    });

    test('insere em nó profundo', () {
      const novo = SduiNode(id: 'x', type: 'text');

      final result = insertChild(root, 'c', 0, novo);

      expect(findNode(result, 'c')!.children.map((n) => n.id), ['x', 'c1']);
    });
  });

  group('setChild / removeNode', () {
    test('setChild substitui o slot único', () {
      const novo = SduiNode(id: 'x', type: 'text');

      final result = setChild(root, 'b', novo);

      expect(findNode(result, 'b')!.child!.id, 'x');
      expect(findNode(result, 'b1'), isNull);
    });

    test('removeNode tira de children', () {
      final result = removeNode(root, 'a');

      expect(result.children.map((n) => n.id), ['b', 'c']);
    });

    test('removeNode tira de child (slot único)', () {
      final result = removeNode(root, 'b1');

      expect(findNode(result, 'b')!.child, isNull);
    });

    test('remover a raiz não tem efeito', () {
      expect(removeNode(root, 'root'), equals(root));
    });
  });

  group('moveNode', () {
    test('move entre pais', () {
      final result = moveNode(root, 'a', 'c', 1);

      expect(result.children.map((n) => n.id), ['b', 'c']);
      expect(findNode(result, 'c')!.children.map((n) => n.id), ['c1', 'a']);
    });

    test('reordena dentro do mesmo pai', () {
      final result = moveNode(root, 'c', 'root', 0);

      expect(result.children.map((n) => n.id), ['c', 'a', 'b']);
    });

    test('não move para a própria subárvore', () {
      expect(moveNode(root, 'b', 'b1', 0), equals(root));
    });

    test('não move a raiz nem para destino inexistente', () {
      expect(moveNode(root, 'root', 'c', 0), equals(root));
      expect(moveNode(root, 'a', 'nao-existe', 0), equals(root));
    });
  });

  group('updateNodeProps', () {
    test('faz merge preservando as demais props', () {
      final base = updateNodeProps(root, 'a', {'data': 'oi', 'fontSize': 14.0});

      final result = updateNodeProps(base, 'a', {'data': 'olá'});

      final node = findNode(result, 'a')!;
      expect(node.properties['data'], 'olá');
      expect(node.properties['fontSize'], 14.0);
    });

    test('valor null remove a chave', () {
      final base = updateNodeProps(root, 'a', {'data': 'oi'});

      final result = updateNodeProps(base, 'a', {'data': null});

      expect(findNode(result, 'a')!.properties.containsKey('data'), isFalse);
    });
  });
}
