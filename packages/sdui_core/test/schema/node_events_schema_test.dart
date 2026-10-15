import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

const _path = 'root.events';

const Map<String, dynamic> _navigate = {
  'action': 'navigate',
  'params': {'slug': 'promocoes'},
};
const Map<String, dynamic> _back = {'action': 'navigateBack'};

Map<String, dynamic> _bind(String source, {Object? fallback = 'x'}) => {
  r'$bind': {'source': source, 'path': 'slug', 'fallback': ?fallback},
};

Map<String, dynamic> _content(Map<String, dynamic> root, {int version = 1}) => {
  'specVersion': version,
  'kind': 'content',
  'id': 'ct_1',
  'name': 'Teste',
  'slug': 'teste',
  'root': root,
};

void main() {
  Either<SpecValidationError, Map<String, dynamic>> parse(
    Map<String, dynamic> events, {
    String type = 'button',
    bool tolerant = false,
    int specVersion = kLatestSpecVersion,
    Iterable<ActionDescriptor> actions = actionCatalog,
  }) => parseNodeEvents(
    events,
    descriptorFor(type)!,
    path: _path,
    specVersion: specVersion,
    tolerant: tolerant,
    actions: actions,
  );

  void expectError(
    Map<String, dynamic> events,
    String message, {
    String type = 'button',
    bool tolerant = false,
    int specVersion = kLatestSpecVersion,
    Iterable<ActionDescriptor> actions = actionCatalog,
  }) {
    final result = parse(
      events,
      type: type,
      tolerant: tolerant,
      specVersion: specVersion,
      actions: actions,
    );
    expect(result.isLeft(), isTrue, reason: '$result');
    expect(result.getLeft().toNullable()!.message, message);
  }

  group('parseNodeEvents: aceita no estrito', () {
    test('gatilho declarado com lista de ações válida', () {
      final events = {
        'onPressed': [_navigate, _back],
      };

      expect(parse(events).getRight().toNullable(), same(events));
    });

    test('lista vazia é mantida', () {
      expect(parse({'onTap': <dynamic>[]}, type: 'container').toNullable(), {
        'onTap': <dynamic>[],
      });
    });

    test('navigateBack sem params', () {
      expect(
        parse({
          'onLongPress': [_back],
        }).isRight(),
        isTrue,
      );
    });

    test('parâmetro extra é ignorado', () {
      expect(
        parse({
          'onPressed': [
            {
              'action': 'navigate',
              'params': {'slug': 'a', 'extra': 1},
            },
          ],
        }).isRight(),
        isTrue,
      );
    });

    test('com action e type no passo, vale action', () {
      expect(
        parse({
          'onPressed': [
            {
              'action': 'navigate',
              'type': 'abrirPorta',
              'params': {'slug': 'a'},
            },
          ],
        }).isRight(),
        isTrue,
      );
    });

    test('passo com type no lugar de action é guardado sem mudança', () {
      const step = {
        'type': 'navigate',
        'params': {'slug': 'a'},
      };

      expect(
        parse({
          'onPressed': [step],
        }).toNullable(),
        {
          'onPressed': [step],
        },
      );
    });
  });

  group('parseNodeEvents: mensagens de recusa', () {
    test('gatilho fora da lista', () {
      expectError({
        'onForcePress': [_back],
      }, 'root.events.onForcePress: gatilho desconhecido');
    });

    test('gatilho que o widget não declara', () {
      expectError(
        {
          'onChanged': [_back],
        },
        'root.events.onChanged: "text" não oferece o gatilho onChanged',
        type: 'text',
      );
    });

    test('valor do gatilho que não é lista', () {
      expectError(
        {
          'onTap': _back,
        },
        'root.events.onTap: esperada uma lista de ações',
        type: 'text',
      );
    });

    test('passo que não é objeto', () {
      expectError(
        {
          'onTap': ['navigate'],
        },
        'root.events.onTap[0]: esperado um objeto',
        type: 'text',
      );
    });

    test('passo sem ação', () {
      expectError(
        {
          'onTap': [
            {
              'params': {'slug': 'a'},
            },
          ],
        },
        'root.events.onTap[0].action: ação ausente',
        type: 'text',
      );
      expectError(
        {
          'onTap': [
            {'action': ''},
          ],
        },
        'root.events.onTap[0].action: ação ausente',
        type: 'text',
      );
    });

    test('ação fora do catálogo', () {
      expectError(
        {
          'onTap': [
            {'action': 'abrirPorta'},
          ],
        },
        'root.events.onTap[0].action: ação "abrirPorta" fora do catálogo',
        type: 'text',
      );
    });

    test('ação indisponível em página', () {
      expectError(
        {
          'onTap': [
            {'action': 'x'},
          ],
        },
        'root.events.onTap[0].action: ação "x" não está disponível em página',
        type: 'text',
        actions: const [
          ActionDescriptor(
            type: 'x',
            label: 'X',
            iconName: 'x',
            category: ActionCategories.utilities,
            contexts: {BindingContext.component},
          ),
        ],
      );
    });

    test('params que não é objeto', () {
      expectError(
        {
          'onTap': [
            {'action': 'navigate', 'params': 'promocoes'},
          ],
        },
        'root.events.onTap[0].params: esperado um objeto',
        type: 'text',
      );
    });

    test('parâmetro obrigatório ausente', () {
      expectError(
        {
          'onTap': [
            {'action': 'navigate', 'params': <String, dynamic>{}},
          ],
        },
        'root.events.onTap[0].params.slug: parâmetro obrigatório ausente',
        type: 'text',
      );
      expectError(
        {
          'onTap': [
            {'action': 'navigate'},
          ],
        },
        'root.events.onTap[0].params.slug: parâmetro obrigatório ausente',
        type: 'text',
      );
    });

    test('parâmetro obrigatório com valor null', () {
      expectError(
        {
          'onTap': [
            {
              'action': 'navigate',
              'params': {'slug': null},
            },
          ],
        },
        'root.events.onTap[0].params.slug: parâmetro obrigatório ausente',
        type: 'text',
      );
    });
  });

  group('parseNodeEvents: binding nos parâmetros', () {
    Map<String, dynamic> withSlug(Object? slug) => {
      'onPressed': [
        {
          'action': 'navigate',
          'params': {'slug': slug},
        },
      ],
    };

    test(r'$bind de pageParam em spec v2 passa', () {
      expect(parse(withSlug(_bind('pageParam'))).isRight(), isTrue);
    });

    test(r'$bind de fonte inexistente reprova', () {
      expectError(
        withSlug(_bind('nada')),
        r'root.events.onPressed[0].params.slug.$bind.source: '
        'fonte "nada" desconhecida',
      );
    });

    test(r'$bind de actionResult reprova em página', () {
      expectError(
        withSlug(_bind('actionResult')),
        r'root.events.onPressed[0].params.slug.$bind.source: '
        'fonte "actionResult" não está disponível em página',
      );
    });

    test('binding em parâmetro obrigatório exige fallback', () {
      expectError(
        withSlug(_bind('pageParam', fallback: null)),
        'root.events.onPressed[0].params.slug: '
        'binding em prop obrigatória exige fallback',
      );
    });

    test(r'$theme e $bind em spec v1 reprovam', () {
      final result = parse(withSlug(_bind('pageParam')), specVersion: 1);
      final theme = parse({
        'onPressed': [
          {
            'action': 'showSnackBar',
            'params': {
              'message': 'oi',
              'backgroundColor': {r'$theme': 'primary'},
            },
          },
        ],
      }, specVersion: 1);

      expect(
        result.getLeft().toNullable()!.message,
        startsWith('root.events.onPressed[0].params.slug: '),
      );
      expect(
        theme.getLeft().toNullable()!.message,
        startsWith('root.events.onPressed[0].params.backgroundColor: '),
      );
    });

    test('enum não ligável recusa binding', () {
      expectError(
        {
          'onPressed': [
            {
              'action': 'apiCall',
              'params': {'url': 'https://a.b', 'method': _bind('pageParam')},
            },
          ],
        },
        'root.events.onPressed[0].params.method: '
        'a prop não aceita token do tema nem binding',
      );
    });
  });

  group('parseNodeEvents: tolerante', () {
    test('descarta gatilho desconhecido e mantém os válidos', () {
      final result = parse(
        {
          'onDrag': [_back],
          'onTap': [_navigate],
        },
        type: 'container',
        tolerant: true,
      );

      expect(result.toNullable(), {
        'onTap': [_navigate],
      });
    });

    test('descarta gatilho não declarado pelo widget', () {
      expect(
        parse(
          {
            'onChanged': [_back],
          },
          type: 'text',
          tolerant: true,
        ).toNullable(),
        isEmpty,
      );
    });

    test('descarta o passo de ação desconhecida e mantém os outros', () {
      final result = parse({
        'onPressed': [
          {'action': 'abrirPorta'},
          _navigate,
        ],
        'onLongPress': [_back],
      }, tolerant: true);

      expect(result.toNullable(), {
        'onPressed': [_navigate],
        'onLongPress': [_back],
      });
    });

    test('remove o gatilho cujos passos foram todos descartados', () {
      final result = parse({
        'onPressed': [
          {'action': 'abrirPorta'},
        ],
        'onLongPress': [_back],
      }, tolerant: true);

      expect(result.toNullable(), {
        'onLongPress': [_back],
      });
    });

    test('descarta o passo de ação indisponível no contexto', () {
      final result = parse(
        {
          'onPressed': [
            {'action': 'x'},
            _back,
          ],
        },
        tolerant: true,
        actions: [
          ...actionCatalog,
          const ActionDescriptor(
            type: 'x',
            label: 'X',
            iconName: 'x',
            category: ActionCategories.utilities,
            contexts: {BindingContext.component},
          ),
        ],
      );

      expect(result.toNullable(), {
        'onPressed': [_back],
      });
    });

    test('lista vazia de entrada é mantida', () {
      expect(
        parse(
          {
            'onTap': <dynamic>[],
            'onDrag': [_back],
          },
          type: 'container',
          tolerant: true,
        ).toNullable(),
        {'onTap': <dynamic>[]},
      );
    });

    test('sem nada a descartar devolve o próprio mapa', () {
      final events = {
        'onPressed': [_navigate],
      };

      expect(parse(events, tolerant: true).toNullable(), same(events));
    });

    test('parâmetro obrigatório ausente reprova também no tolerante', () {
      expectError(
        {
          'onPressed': [
            {'action': 'navigate'},
          ],
        },
        'root.events.onPressed[0].params.slug: parâmetro obrigatório ausente',
        tolerant: true,
      );
    });

    test('erro de estrutura reprova também no tolerante', () {
      expectError(
        {'onPressed': 'navigate'},
        'root.events.onPressed: esperada uma lista de ações',
        tolerant: true,
      );
    });

    test('o estrito recusa os mesmos dois casos', () {
      expect(
        parse({
          'onDrag': [_back],
        }, type: 'container').isLeft(),
        isTrue,
      );
      expect(
        parse({
          'onPressed': [
            {'action': 'abrirPorta'},
          ],
        }).isLeft(),
        isTrue,
      );
    });
  });

  group('parseContentSpec com events', () {
    Map<String, dynamic> tree(Map<String, dynamic> leaf) => {
      'id': 'root',
      'type': 'column',
      'children': [leaf],
    };

    test('onChanged num text reprova no estrito', () {
      final result = parseContentSpec(
        _content(
          tree({
            'id': 'a',
            'type': 'text',
            'props': {'data': 'oi'},
            'events': {
              'onChanged': [_back],
            },
          }),
        ),
      );

      expect(
        result.getLeft().toNullable()!.message,
        'root.children[0].events.onChanged: '
        '"text" não oferece o gatilho onChanged',
      );
    });

    test('ação fora do catálogo reprova no estrito', () {
      final result = parseContentSpec(
        _content(
          tree({
            'id': 'a',
            'type': 'button',
            'events': {
              'onPressed': [
                {'type': 'abrirPorta'},
              ],
            },
          }),
        ),
      );

      expect(
        result.getLeft().toNullable()!.message,
        'root.children[0].events.onPressed[0].action: '
        'ação "abrirPorta" fora do catálogo',
      );
    });

    test('parâmetro obrigatório ausente reprova no estrito', () {
      final result = parseContentSpec(
        _content(
          tree({
            'id': 'a',
            'type': 'button',
            'events': {
              'onPressed': [
                {'action': 'copyToClipboard'},
              ],
            },
          }),
        ),
      );

      expect(
        result.getLeft().toNullable()!.message,
        'root.children[0].events.onPressed[0].params.text: '
        'parâmetro obrigatório ausente',
      );
    });

    test('round-trip estrito devolve o mesmo events', () {
      final events = {
        'onPressed': [
          _navigate,
          {
            'type': 'showSnackBar',
            'params': {'message': 'oi', 'durationMs': 2000},
          },
        ],
        'onLongPress': <dynamic>[],
      };
      final json = _content(
        tree({'id': 'a', 'type': 'button', 'events': events}),
      );

      final content = parseContentSpec(json).getRight().toNullable()!;
      final root = content.toJson()['root'] as Map<String, dynamic>;
      final leaf = (root['children'] as List).single as Map<String, dynamic>;

      expect(leaf['events'], events);
      expect(parseContentSpec(content.toJson()).toNullable(), content);
    });

    test('round-trip tolerante devolve events sem o descartado', () {
      final json = _content(
        tree({
          'id': 'a',
          'type': 'container',
          'events': {
            'onDrag': [_back],
            'onTap': [
              {'action': 'abrirPorta'},
              _navigate,
            ],
          },
        }),
      );

      final content = parseContentSpec(json, tolerant: true).toNullable()!;
      final root = content.toJson()['root'] as Map<String, dynamic>;
      final leaf = (root['children'] as List).single as Map<String, dynamic>;

      expect(leaf['events'], {
        'onTap': [_navigate],
      });
    });

    test('nó de tipo desconhecido no tolerante mantém events intacto', () {
      final events = {
        'onSwipe': [
          {'action': 'abrirPorta'},
        ],
      };
      final content = parseContentSpec(
        _content(tree({'id': 'a', 'type': 'futureWidget', 'events': events})),
        tolerant: true,
      ).toNullable()!;

      expect(content.root!.children.single.events, events);
    });
  });
}
