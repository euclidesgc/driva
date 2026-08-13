import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  const tree = SduiNode(
    id: 'root',
    type: 'column',
    children: [
      SduiNode(
        id: 'card',
        type: 'card',
        child: SduiNode(id: 'inner', type: 'row'),
      ),
      SduiNode(id: 'txt', type: 'text'),
      SduiNode(id: 'empty_container', type: 'container'),
    ],
  );

  group('resolveDrop', () {
    test('alvo de slot multi recebe no fim da lista', () {
      expect(
        resolveDrop(tree, 'root'),
        const DropAccepted(parentId: 'root', index: 3, redirected: false),
      );
    });

    test('alvo de slot único vazio recebe no child', () {
      expect(
        resolveDrop(tree, 'empty_container'),
        const DropAccepted(
          parentId: 'empty_container',
          index: 0,
          redirected: false,
        ),
      );
    });

    test('alvo folha sobe para o pai e entra logo depois dele', () {
      expect(
        resolveDrop(tree, 'txt'),
        const DropAccepted(parentId: 'root', index: 2, redirected: true),
      );
    });

    test('alvo de slot único ocupado sobe para o pai', () {
      expect(
        resolveDrop(tree, 'card'),
        const DropAccepted(parentId: 'root', index: 1, redirected: true),
      );
    });

    test('slot único ocupado recebe de volta o próprio ocupante', () {
      expect(
        resolveDrop(tree, 'card', movingNodeId: 'inner'),
        const DropAccepted(parentId: 'card', index: 0, redirected: false),
      );
    });

    test('recusa mover um nó para dentro da própria subárvore', () {
      expect(
        resolveDrop(tree, 'inner', movingNodeId: 'card'),
        const DropRefused(DropRefusal.cycle),
      );
    });

    test('recusa alvo inexistente', () {
      expect(
        resolveDrop(tree, 'fantasma'),
        const DropRefused(DropRefusal.unknownTarget),
      );
    });

    test('recusa quando nenhum ancestral aceita filhos (raiz folha)', () {
      const leafRoot = SduiNode(id: 'só', type: 'text');
      expect(
        resolveDrop(leafRoot, 'só'),
        const DropRefused(DropRefusal.noSlotAvailable),
      );
    });

    test('sobe mais de um nível até achar quem aceita', () {
      const deep = SduiNode(
        id: 'root',
        type: 'column',
        children: [
          SduiNode(
            id: 'ct',
            type: 'container',
            child: SduiNode(id: 'leaf', type: 'divider'),
          ),
        ],
      );
      // divider é folha; container está ocupado; sobra a column da raiz.
      expect(
        resolveDrop(deep, 'leaf'),
        const DropAccepted(parentId: 'root', index: 1, redirected: true),
      );
    });

    test('o encaixe resolvido nunca produz documento que o schema recusa', () {
      for (final targetId in ['root', 'card', 'inner', 'txt', 'container']) {
        final resolution = resolveDrop(tree, targetId);
        if (resolution is! DropAccepted) continue;
        final attached = attachNode(
          tree,
          resolution.parentId,
          resolution.index,
          defaultNode('text', id: 'novo'),
        );
        expect(attached, isNotNull, reason: 'alvo $targetId');
        final json = {
          'specVersion': kSpecVersion,
          'kind': 'content',
          'id': 'ct',
          'name': 'N',
          'slug': 'n',
          'root': attached!.toJson(),
        };
        expect(
          parseContentSpec(json).isRight(),
          isTrue,
          reason: 'alvo $targetId gerou documento inválido',
        );
      }
    });
  });
}
