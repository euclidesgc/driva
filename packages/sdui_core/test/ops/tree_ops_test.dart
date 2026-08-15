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

    test('destino de slot único recebe o nó em child, não em children', () {
      final semFilho = setChild(root, 'b', null);

      final result = moveNode(semFilho, 'a', 'b', 0);

      final destino = findNode(result, 'b')!;
      expect(destino.child?.id, 'a');
      expect(destino.children, isEmpty);
    });

    test('não move para slot único já ocupado', () {
      expect(moveNode(root, 'a', 'b', 0), equals(root));
    });

    test('não move para folha', () {
      expect(moveNode(root, 'b', 'a', 0), equals(root));
    });

    test('não move para tipo fora do catálogo', () {
      const desconhecido = SduiNode(id: 'z', type: 'inexistente');
      final comDesconhecido = insertChild(root, 'root', 3, desconhecido);

      expect(moveNode(comDesconhecido, 'a', 'z', 0), equals(comDesconhecido));
    });

    test('nunca produz documento que o schema recusa', () {
      const alvos = ['root', 'a', 'b', 'b1', 'c', 'c1'];
      final origem = setChild(root, 'b', null);

      for (final destino in alvos) {
        final movido = moveNode(origem, 'a', destino, 0);
        final documento = ContentSpec(
          specVersion: kSpecVersion,
          id: 'ct',
          name: 'Conteúdo',
          slug: 'conteudo',
          root: movido,
        );

        expect(
          parseContentSpec(documento.toJson()).isRight(),
          isTrue,
          reason: 'mover "a" para "$destino" gerou documento inválido',
        );
      }
    });
  });

  group('wrapNode', () {
    test('envolver a raiz troca a raiz e preserva a subárvore original', () {
      final result = wrapNode(root, 'root', 'row', newId: 'w');

      expect(result, isNotNull);
      expect(result!.id, 'w');
      expect(result.type, 'row');
      expect(result.children.single, root);
    });

    test(
      'envolver o ocupante de um slot único mantém o pai e troca só o child',
      () {
        final result = wrapNode(root, 'b1', 'column', newId: 'w')!;

        final pai = findNode(result, 'b')!;
        expect(pai.child?.id, 'w');
        expect(pai.child?.children.single.id, 'b1');
        expect(findNode(result, 'b1'), equals(b1));
      },
    );

    test('envolver um nó em slot múltiplo não mexe nos irmãos', () {
      final result = wrapNode(root, 'b', 'row', newId: 'w')!;

      expect(result.children.map((n) => n.id), ['a', 'w', 'c']);
      expect(result.children[0], equals(root.children[0]));
      expect(result.children[2], equals(root.children[2]));
      expect(findNode(result, 'w')!.children.single, equals(root.children[1]));
    });

    test('wrapperType folha devolve null', () {
      expect(wrapNode(root, 'a', 'text', newId: 'w'), isNull);
    });

    test('wrapperType de slot único devolve null', () {
      expect(wrapNode(root, 'a', 'container', newId: 'w'), isNull);
    });

    test('wrapperType fora do catálogo devolve null', () {
      expect(wrapNode(root, 'a', 'inexistente', newId: 'w'), isNull);
    });

    test('nodeId inexistente devolve null', () {
      expect(wrapNode(root, 'nao-existe', 'column', newId: 'w'), isNull);
    });

    test('newId que já existe na árvore devolve null', () {
      expect(wrapNode(root, 'b1', 'column', newId: 'b1'), isNull);
      expect(wrapNode(root, 'a', 'column', newId: 'c'), isNull);
    });

    test('o resultado sobrevive a um round-trip toJson/parseContentSpec', () {
      final result = wrapNode(root, 'root', 'row', newId: 'w')!;
      final documento = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct',
        name: 'Conteúdo',
        slug: 'conteudo',
        root: result,
      );

      final parsed = parseContentSpec(
        documento.toJson(),
      ).getRight().toNullable();

      expect(parsed, isNotNull);
      expect(parsed!.root, result);
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

  group('cloneWithNewIds', () {
    Set<String> idsOf(SduiNode node) => {
      node.id,
      if (node.child != null) ...idsOf(node.child!),
      for (final child in node.children) ...idsOf(child),
    };

    String Function() sequentialIds() {
      var next = 0;
      return () => 'clone_${next++}';
    }

    test('preserva a forma da subárvore', () {
      final clone = cloneWithNewIds(root, sequentialIds());

      expect(clone.type, 'column');
      expect(clone.children.map((n) => n.type), ['text', 'container', 'row']);
      expect(clone.children[1].child?.type, 'text');
      expect(clone.children[2].children.single.type, 'icon');
    });

    test('nenhum id do clone existe no original', () {
      final clone = cloneWithNewIds(root, sequentialIds());

      expect(idsOf(clone), hasLength(idsOf(root).length));
      expect(idsOf(clone).intersection(idsOf(root)), isEmpty);
    });

    test('properties e events seguem intactos', () {
      const original = SduiNode(
        id: 'orig',
        type: 'button',
        properties: {'label': 'Enviar'},
        events: {
          'onTap': {'action': 'navigate'},
        },
      );

      final clone = cloneWithNewIds(original, sequentialIds());

      expect(clone.properties, original.properties);
      expect(clone.events, original.events);
      expect(clone.id, isNot('orig'));
    });

    test('o original não é alterado', () {
      final before = root.toJson();

      cloneWithNewIds(root, sequentialIds());

      expect(root.toJson(), before);
    });
  });
}
