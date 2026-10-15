import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

SduiNode _tree(Map<String, dynamic> props) => SduiNode(
  id: 'root',
  type: 'column',
  children: [
    SduiNode(id: 'title', type: 'text', properties: props),
  ],
);

Map<String, dynamic> _propsOf(SduiNode root) =>
    findNode(root, 'title')!.properties;

void main() {
  const binding = BoundPropValue(
    source: BindingSourceIds.pageParam,
    path: 'nomeCliente',
    fallback: 'Visitante',
    preview: 'Maria',
  );

  group('bindNodeProp', () {
    test('guarda o literal atual em literal', () {
      final root = bindNodeProp(
        _tree({'text': 'Olá'}),
        'title',
        'text',
        binding,
      );

      expect(_propsOf(root)['text'], {
        r'$bind': {
          'source': 'pageParam',
          'path': 'nomeCliente',
          'fallback': 'Visitante',
          'preview': 'Maria',
          'literal': 'Olá',
        },
      });
    });

    test('religar uma prop já ligada preserva o literal antigo', () {
      final first = bindNodeProp(
        _tree({'text': 'Olá'}),
        'title',
        'text',
        binding,
      );

      final second = bindNodeProp(
        first,
        'title',
        'text',
        const BoundPropValue(
          source: BindingSourceIds.pageParam,
          path: 'outroNome',
        ),
      );

      expect(_propsOf(second)['text'], {
        r'$bind': {
          'source': 'pageParam',
          'path': 'outroNome',
          'literal': 'Olá',
        },
      });
    });

    test('a fonte legada grava {{path}} sem literal', () {
      final root = bindNodeProp(
        _tree({'text': 'Olá'}),
        'title',
        'text',
        const BoundPropValue.legacy('user.name'),
      );

      expect(_propsOf(root)['text'], '{{user.name}}');
    });

    test('prop ausente é ligada sem literal', () {
      final root = bindNodeProp(_tree({}), 'title', 'text', binding);

      final stored = _propsOf(root)['text'] as Map;
      expect((stored[r'$bind'] as Map).containsKey('literal'), isFalse);
    });

    test('nó inexistente devolve o root idêntico', () {
      final tree = _tree({'text': 'Olá'});

      expect(
        identical(bindNodeProp(tree, 'nao', 'text', binding), tree),
        isTrue,
      );
    });
  });

  group('unbindNodeProp', () {
    test('ligar e desligar devolve o literal guardado', () {
      final bound = bindNodeProp(
        _tree({'text': 'Olá'}),
        'title',
        'text',
        binding,
      );

      final root = unbindNodeProp(bound, 'title', 'text');

      expect(_propsOf(root), {'text': 'Olá'});
    });

    test(r'desligar um $bind sem literal remove a chave', () {
      final tree = _tree({
        'text': {
          r'$bind': {'source': 'pageParam', 'path': 'nomeCliente'},
        },
        'maxLines': 2,
      });

      final root = unbindNodeProp(tree, 'title', 'text');

      expect(_propsOf(root), {'maxLines': 2});
    });

    test('desligar um {{x}} legado remove a chave', () {
      final root = unbindNodeProp(
        _tree({'text': '{{user.name}}'}),
        'title',
        'text',
      );

      expect(_propsOf(root).containsKey('text'), isFalse);
    });

    test('desligar uma prop sem binding devolve o root idêntico', () {
      final tree = _tree({'text': 'Olá'});

      expect(identical(unbindNodeProp(tree, 'title', 'text'), tree), isTrue);
      expect(identical(unbindNodeProp(tree, 'title', 'outra'), tree), isTrue);
      expect(identical(unbindNodeProp(tree, 'nao', 'text'), tree), isTrue);
    });
  });

  group('literalUnder', () {
    test('literal comum é o próprio valor', () {
      expect(literalUnder('Olá'), 'Olá');
      expect(literalUnder(true), isTrue);
      expect(literalUnder(const {'top': 8}), {'top': 8});
    });

    test(r'$bind devolve o literal guardado, ou null sem ele', () {
      expect(
        literalUnder(const {
          r'$bind': {'source': 'pageParam', 'path': 'x', 'literal': 'Olá'},
        }),
        'Olá',
      );
      expect(
        literalUnder(const {
          r'$bind': {'source': 'pageParam', 'path': 'x'},
        }),
        isNull,
      );
    });

    test(r'{{x}}, $theme e ausente não têm literal', () {
      expect(literalUnder('{{user.name}}'), isNull);
      expect(literalUnder(const {r'$theme': 'primary'}), isNull);
      expect(literalUnder(null), isNull);
    });
  });
}
