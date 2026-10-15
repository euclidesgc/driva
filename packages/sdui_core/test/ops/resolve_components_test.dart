import 'dart:convert';
import 'dart:io';

import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _loadFixture(String name) {
  final local = File('test/fixtures/$name');
  final file = local.existsSync()
      ? local
      : File('packages/sdui_core/test/fixtures/$name');
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
}

ContentSpec _fixture(String name) => parseContentSpec(
  _loadFixture(name),
).match((error) => fail(error.message), (spec) => spec);

ContentSpec _component(
  String id, {
  String? name,
  List<ComponentParam> params = const [],
  SduiNode? root,
}) => ContentSpec(
  specVersion: 2,
  id: id,
  name: name ?? id,
  slug: id,
  kind: ContentKind.component,
  params: params,
  root: root,
);

ComponentParam _textParam(
  String name, {
  bool isRequired = false,
  bool isList = false,
  Object? defaultValue,
}) => ComponentParam(
  name: name,
  type: ComponentParamType.text,
  isList: isList,
  isRequired: isRequired,
  defaultValue: defaultValue,
);

SduiNode _instance(
  String id,
  String componentId, [
  Map<String, dynamic>? args,
]) => SduiNode(
  id: id,
  type: ComponentInstance.type,
  properties: {
    ComponentInstance.componentIdKey: componentId,
    ComponentInstance.argsKey: ?args,
  },
);

SduiNode _text(String id, Map<String, dynamic> props) =>
    SduiNode(id: id, type: 'text', properties: props);

Map<String, dynamic> _param(String path, {Object? fallback}) => {
  r'$bind': {
    'source': BindingSourceIds.componentParam,
    'path': path,
    'fallback': ?fallback,
  },
};

ComponentLookup _lookupOf(List<ContentSpec> specs) {
  final byId = {for (final spec in specs) spec.id: spec};
  return (id) => byId[id];
}

List<ContentSpec> _nestedChain(int levels) => [
  for (var level = 1; level <= levels; level++)
    _component(
      'c$level',
      name: 'Nível $level',
      root: level == levels
          ? _text('t', {'data': 'fim'})
          : _instance('n', 'c${level + 1}'),
    ),
];

Iterable<SduiNode> _walk(SduiNode node) sync* {
  yield node;
  if (node.child case final child?) yield* _walk(child);
  for (final child in node.children) {
    yield* _walk(child);
  }
}

bool _isComponentParamBind(Object? value) =>
    value is Map &&
    value[r'$bind'] is Map &&
    (value[r'$bind'] as Map)['source'] == BindingSourceIds.componentParam;

void main() {
  final card = _fixture('component_card.json');
  final selo = _fixture('component_selo.json');
  final cardLookup = _lookupOf([card, selo]);

  group('resolveComponents — erros do DoD', () {
    test('obrigatório sem default e sem arg dá MissingRequiredArg', () {
      final result = resolveComponents(
        _instance('inst1', 'c-card'),
        cardLookup,
      );

      expect(
        result.getLeft().toNullable(),
        const MissingRequiredArg(
          instanceId: 'inst1',
          componentName: 'Card de oferta',
          paramName: 'titulo',
        ),
      );
    });

    test('arg literal de tipo errado dá ArgTypeMismatch', () {
      final result = resolveComponents(
        _instance('inst1', 'c-card', {'titulo': 3}),
        cardLookup,
      );

      expect(
        result.getLeft().toNullable(),
        const ArgTypeMismatch(
          instanceId: 'inst1',
          componentName: 'Card de oferta',
          paramName: 'titulo',
          expected: ComponentParamType.text,
          expectedList: false,
        ),
      );
    });

    test('texto solto num parâmetro de lista dá ArgTypeMismatch', () {
      final tags = _component(
        'c-tags',
        name: 'Tags',
        params: [_textParam('tags', isList: true)],
        root: _text('t', {'data': 'tags'}),
      );

      final result = resolveComponents(
        _instance('inst1', 'c-tags', {'tags': 'x'}),
        _lookupOf([tags]),
      );

      expect(
        result.getLeft().toNullable(),
        const ArgTypeMismatch(
          instanceId: 'inst1',
          componentName: 'Tags',
          paramName: 'tags',
          expected: ComponentParamType.text,
          expectedList: true,
        ),
      );
    });

    test('componentId inexistente dá ComponentNotFound', () {
      final result = resolveComponents(_instance('inst1', 'c9'), cardLookup);

      expect(
        result.getLeft().toNullable(),
        const ComponentNotFound(instanceId: 'inst1', componentId: 'c9'),
      );
    });

    test('componentId de um conteúdo dá ComponentNotFound', () {
      final page = _fixture('content_with_instances.json');

      final result = resolveComponents(
        _instance('inst1', page.id),
        _lookupOf([page]),
      );

      expect(
        result.getLeft().toNullable(),
        ComponentNotFound(instanceId: 'inst1', componentId: page.id),
      );
    });
  });

  group('resolveComponents — valor dos parâmetros', () {
    test('o arg vira a prop e o id deriva do id da instância', () {
      final result = resolveComponents(
        _instance('inst1', 'c-card', {'titulo': 'Olá'}),
        cardLookup,
      );

      final node = result.getRight().toNullable();
      expect(node?.id, 'inst1/t');
      expect(node?.type, 'text');
      expect(node?.properties, {'data': 'Olá'});
    });

    test('sem o arg vale o default do parâmetro', () {
      final component = _component(
        'c1',
        params: [_textParam('titulo', defaultValue: 'Padrão')],
        root: _text('t', {'data': _param('titulo', fallback: 'Reserva')}),
      );

      final node = resolveComponents(
        _instance('inst1', 'c1'),
        _lookupOf([component]),
      ).getRight().toNullable();

      expect(node?.properties['data'], 'Padrão');
    });

    test('sem arg nem default vale o fallback do binding', () {
      final component = _component(
        'c1',
        params: [_textParam('titulo')],
        root: _text('t', {'data': _param('titulo', fallback: 'Reserva')}),
      );

      final node = resolveComponents(
        _instance('inst1', 'c1'),
        _lookupOf([component]),
      ).getRight().toNullable();

      expect(node?.properties['data'], 'Reserva');
    });

    test('sem arg, default nem fallback a chave sai das props', () {
      final component = _component(
        'c1',
        params: [_textParam('cor')],
        root: _text('t', {'data': 'fixo', 'color': _param('cor')}),
      );

      final node = resolveComponents(
        _instance('inst1', 'c1'),
        _lookupOf([component]),
      ).getRight().toNullable();

      expect(node?.properties, {'data': 'fixo'});
    });

    test('arg nulo conta como ausente', () {
      final result = resolveComponents(
        _instance('inst1', 'c-card', {'titulo': null}),
        cardLookup,
      );

      expect(result.getLeft().toNullable(), isA<MissingRequiredArg>());
    });

    test('arg não declarado é ignorado', () {
      final result = resolveComponents(
        _instance('inst1', 'c-card', {'titulo': 'Oi', 'extra': 3}),
        cardLookup,
      );

      expect(result.getRight().toNullable()?.properties, {'data': 'Oi'});
    });

    test(r'arg $theme passa sem conferência de tipo', () {
      const themeRef = {r'$theme': 'primary'};

      final result = resolveComponents(
        _instance('inst1', 'c-card', {'titulo': themeRef}),
        cardLookup,
      );

      expect(result.getRight().toNullable()?.properties['data'], themeRef);
    });

    test('arg com a expressão legada passa sem conferência de tipo', () {
      final component = _component(
        'c1',
        params: [
          const ComponentParam(
            name: 'quantidade',
            type: ComponentParamType.integer,
            isList: false,
            isRequired: true,
          ),
        ],
        root: _text('t', {'data': 'x'}),
      );

      final result = resolveComponents(
        _instance('inst1', 'c1', {'quantidade': '{{carrinho.total}}'}),
        _lookupOf([component]),
      );

      expect(result.isRight(), isTrue, reason: result.toString());
    });

    test('parâmetro especial ausente e não obrigatório é aceito', () {
      final result = resolveComponents(
        _instance('inst1', 'c-card', {'titulo': 'Oi'}),
        cardLookup,
      );

      expect(card.paramNamed('aoTocar')?.type, ComponentParamType.action);
      expect(result.isRight(), isTrue, reason: result.toString());
    });

    test(r'$bind de fonte de página dentro do componente fica intacto', () {
      final pageBind = {
        r'$bind': {
          'source': BindingSourceIds.pageParam,
          'path': 'usuario.nome',
          'fallback': 'Visitante',
        },
      };
      final component = _component(
        'c1',
        root: _text('t', {'data': pageBind}),
      );

      final node = resolveComponents(
        _instance('inst1', 'c1'),
        _lookupOf([component]),
      ).getRight().toNullable();

      expect(node?.properties['data'], pageBind);
    });
  });

  group('resolveComponents — aninhamento', () {
    final vitrine = _component(
      'c-vitrine',
      name: 'Vitrine',
      params: [_textParam('titulo')],
      root: SduiNode(
        id: 'col',
        type: 'column',
        children: [
          _instance('selo', 'c-selo', {'rotulo': _param('titulo')}),
        ],
      ),
    );

    test(r'ids encadeados e $bind repassado ao componente de dentro', () {
      final node = resolveComponents(
        _instance('inst', 'c-vitrine', {'titulo': 'Oi'}),
        _lookupOf([vitrine, selo]),
      ).getRight().toNullable();

      expect(node?.id, 'inst/col');
      final texto = node!.children.single;
      expect(texto.id, 'inst/selo/texto');
      expect(texto.properties, {'data': 'Oi', 'color': '#D32F2F'});
    });

    test(
      r'$bind repassado sem valor deixa o obrigatório de dentro sem arg',
      () {
        final result = resolveComponents(
          _instance('inst', 'c-vitrine'),
          _lookupOf([vitrine, selo]),
        );

        expect(
          result.getLeft().toNullable(),
          const MissingRequiredArg(
            instanceId: 'inst/selo',
            componentName: 'Selo',
            paramName: 'rotulo',
          ),
        );
      },
    );

    test('A → A dá ComponentCycle com a cadeia de nomes', () {
      final a = _component('a', name: 'A', root: _instance('de-novo', 'a'));

      final result = resolveComponents(_instance('inst', 'a'), _lookupOf([a]));

      expect(
        result.getLeft().toNullable(),
        const ComponentCycle(instanceId: 'inst/de-novo', chain: ['A', 'A']),
      );
    });

    test('A → B → A dá ComponentCycle com a cadeia de nomes', () {
      final a = _component('a', name: 'A', root: _instance('vai', 'b'));
      final b = _component('b', name: 'B', root: _instance('volta', 'a'));

      final result = resolveComponents(
        _instance('inst', 'a'),
        _lookupOf([a, b]),
      );

      expect(
        result.getLeft().toNullable(),
        const ComponentCycle(
          instanceId: 'inst/vai/volta',
          chain: ['A', 'B', 'A'],
        ),
      );
    });

    test('cinco níveis aninhados resolvem', () {
      final result = resolveComponents(
        _instance('inst', 'c1'),
        _lookupOf(_nestedChain(5)),
      );

      final node = result.getRight().toNullable();
      expect(node?.id, 'inst/n/n/n/n/t');
      expect(node?.properties, {'data': 'fim'});
    });

    test('seis níveis dão ComponentDepthExceeded com limite 5', () {
      final result = resolveComponents(
        _instance('inst', 'c1'),
        _lookupOf(_nestedChain(6)),
      );

      expect(kMaxComponentDepth, 5);
      expect(
        result.getLeft().toNullable(),
        ComponentDepthExceeded(
          instanceId: 'inst/n/n/n/n/n',
          limit: 5,
          chain: [for (var i = 1; i <= 6; i++) 'Nível $i'],
        ),
      );
    });
  });

  group('resolveComponents — componente sem root', () {
    final vazio = _component('c-vazio');

    test('instância na raiz dá Right(null)', () {
      final result = resolveComponents(
        _instance('inst', 'c-vazio'),
        _lookupOf([vazio]),
      );

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), isNull);
    });

    test('instância some dos children do pai', () {
      final root = SduiNode(
        id: 'col',
        type: 'column',
        children: [
          _text('a', {'data': 'A'}),
          _instance('inst', 'c-vazio'),
          _text('b', {'data': 'B'}),
        ],
      );

      final node = resolveComponents(
        root,
        _lookupOf([vazio]),
      ).getRight().toNullable();

      expect(node?.children.map((child) => child.id), ['a', 'b']);
    });

    test('instância some do child do pai', () {
      final root = SduiNode(
        id: 'caixa',
        type: 'container',
        child: _instance('inst', 'c-vazio'),
      );

      final node = resolveComponents(
        root,
        _lookupOf([vazio]),
      ).getRight().toNullable();

      expect(node?.id, 'caixa');
      expect(node?.child, isNull);
    });
  });

  group('resolveComponents — página com instâncias', () {
    final page = _fixture('content_with_instances.json');
    final pristine = _fixture('content_with_instances.json');

    test(r'não sobra instância nem $bind componentParam nas props', () {
      final resolved = resolveComponents(
        page.root!,
        cardLookup,
      ).getRight().toNullable();

      final nodes = _walk(resolved!).toList();
      expect(nodes.where(ComponentInstance.isInstance), isEmpty);
      expect(
        nodes.expand((node) => node.properties.values),
        isNot(contains(predicate(_isComponentParamBind))),
      );
      expect(nodes.map((node) => node.id), [
        'raiz',
        'saudacao',
        'oferta/t',
        'moldura',
        'novidade/texto',
      ]);
    });

    test(r'$bind de fonte de página fica intacto', () {
      final resolved = resolveComponents(
        page.root!,
        cardLookup,
      ).getRight().toNullable();

      expect(
        resolved!.children.first.properties,
        page.root!.children.first.properties,
      );
    });

    test('a árvore de entrada não muda', () {
      resolveComponents(page.root!, cardLookup);

      expect(page.root, pristine.root);
    });

    test('a mesma entrada dá o mesmo resultado', () {
      final first = resolveComponents(page.root!, cardLookup);
      final second = resolveComponents(page.root!, cardLookup);

      expect(first.getRight().toNullable(), isNotNull);
      expect(second.getRight().toNullable(), first.getRight().toNullable());
    });
  });

  group('resolveComponentInstance', () {
    test('resolve a instância como resolveComponents', () {
      final instance = _instance('inst1', 'c-selo', {'rotulo': 'Novo'});

      final node = resolveComponentInstance(
        instance,
        cardLookup,
      ).getRight().toNullable();

      expect(node?.id, 'inst1/texto');
      expect(node?.properties, {'data': 'Novo', 'color': '#D32F2F'});
    });

    test('devolve o erro tipado da instância', () {
      expect(
        resolveComponentInstance(
          _instance('inst1', 'c9'),
          cardLookup,
        ).getLeft().toNullable(),
        const ComponentNotFound(instanceId: 'inst1', componentId: 'c9'),
      );
    });
  });
}
