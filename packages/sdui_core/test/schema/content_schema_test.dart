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

void main() {
  group('parseContentSpec', () {
    test('aceita o conteúdo da fixture e preserva a árvore', () {
      final result = parseContentSpec(_loadFixture('content_valid.json'));

      final content = result.getRight().toNullable();
      expect(content, isNotNull, reason: result.toString());
      expect(content!.id, 'ct_home_promo');
      expect(content.slug, 'home');
      expect(content.root!.type, 'column');
      expect(content.root!.children, hasLength(8));

      final banner = content.root!.children.first;
      expect(banner.type, 'container');
      expect(banner.properties['color'], '#6C4CF1');
      expect(banner.child?.type, 'text');

      final cta = content.root!.children.firstWhere((n) => n.type == 'button');
      expect(cta.events['onPressed'], isA<List<dynamic>>());

      final field = content.root!.children.firstWhere(
        (n) => n.type == 'textField',
      );
      expect(field.properties['value'], 'PROMO10');
    });

    test('roundtrip: toJson de um conteúdo parseado re-parseia igual', () {
      final content = parseContentSpec(
        _loadFixture('content_valid.json'),
      ).getRight().toNullable()!;
      final reparsed = parseContentSpec(
        content.toJson(),
      ).getRight().toNullable();

      expect(reparsed, equals(content));
    });

    test('rejeita specVersion desconhecida', () {
      final json = _loadFixture('content_valid.json')..['specVersion'] = 99;

      final error = parseContentSpec(json).getLeft().toNullable();

      expect(error, isNotNull);
      expect(error!.message, contains('specVersion'));
    });

    test('rejeita kind diferente de content', () {
      final json = _loadFixture('content_valid.json')..['kind'] = 'widget';

      expect(parseContentSpec(json).isLeft(), isTrue);
    });

    test('root ausente é válido: conteúdo vazio (root null)', () {
      final json = _loadFixture('content_valid.json')..remove('root');

      final content = parseContentSpec(json).getRight().toNullable();

      expect(content, isNotNull);
      expect(content!.root, isNull);
    });

    test('root null explícito é válido: conteúdo vazio', () {
      final json = _loadFixture('content_valid.json')..['root'] = null;

      final content = parseContentSpec(json).getRight().toNullable();

      expect(content, isNotNull);
      expect(content!.root, isNull);
    });

    test('root de qualquer tipo do catálogo é aceito (não só column)', () {
      final json = _loadFixture('content_valid.json');
      json['root'] = {
        'id': 'nd_root',
        'type': 'container',
        'props': {'color': '#112233'},
        'child': {
          'id': 'nd_text',
          'type': 'text',
          'props': {'data': 'oi'},
        },
      };

      final content = parseContentSpec(json).getRight().toNullable();

      expect(content, isNotNull, reason: parseContentSpec(json).toString());
      expect(content!.root?.type, 'container');
      expect(content.root?.child?.type, 'text');
    });

    test('toJson sem root omite a chave', () {
      const content = ContentSpec(
        specVersion: kSpecVersion,
        id: 'ct_vazio',
        name: 'Vazio',
        slug: 'vazio',
      );

      final json = content.toJson();

      expect(json.containsKey('root'), isFalse);
      expect(parseContentSpec(json).getRight().toNullable(), equals(content));
    });

    test('safeArea ausente vira mapa vazio (tudo no padrão)', () {
      final content = parseContentSpec({
        'specVersion': kSpecVersion,
        'kind': 'content',
        'id': 'ct',
        'name': 'N',
        'slug': 'n',
      }).getRight().toNullable();

      expect(content!.safeArea, isEmpty);
      expect(content.toJson().containsKey('safeArea'), isFalse);
    });

    test('safeArea é preservada no parse e no roundtrip', () {
      const json = {
        'specVersion': kSpecVersion,
        'kind': 'content',
        'id': 'ct',
        'name': 'N',
        'slug': 'n',
        'safeArea': {
          'enabled': true,
          'bottom': false,
          'minimum': {'all': 8},
        },
      };
      final content = parseContentSpec(json).getRight().toNullable();

      expect(content!.safeArea['bottom'], isFalse);
      expect(content.toJson()['safeArea'], json['safeArea']);
      expect(
        parseContentSpec(content.toJson()).getRight().toNullable(),
        content,
      );
    });

    test('safeArea que não é objeto é recusada', () {
      final result = parseContentSpec({
        'specVersion': kSpecVersion,
        'kind': 'content',
        'id': 'ct',
        'name': 'N',
        'slug': 'n',
        'safeArea': 'sim',
      });
      expect(result.isLeft(), isTrue);
    });

    test('rejeita nó com tipo fora do catálogo', () {
      final json = _loadFixture('content_valid.json');
      json['root'] = {
        'id': 'nd_root',
        'type': 'column',
        'children': [
          {'id': 'nd_x', 'type': 'carousel3d'},
        ],
      };

      final error = parseContentSpec(json).getLeft().toNullable();

      expect(error!.message, contains('carousel3d'));
    });

    test('rejeita folha com filhos (contrato de slot)', () {
      final json = _loadFixture('content_valid.json');
      json['root'] = {
        'id': 'nd_root',
        'type': 'column',
        'children': [
          {
            'id': 'nd_text',
            'type': 'text',
            'props': {'data': 'oi'},
            'children': [
              {'id': 'nd_filho', 'type': 'text'},
            ],
          },
        ],
      };

      final error = parseContentSpec(json).getLeft().toNullable();

      expect(error!.message, contains('folha'));
    });

    test('rejeita nó sem id', () {
      final json = _loadFixture('content_valid.json');
      json['root'] = {
        'id': 'nd_root',
        'type': 'column',
        'children': [
          {'type': 'text'},
        ],
      };

      expect(parseContentSpec(json).isLeft(), isTrue);
    });
  });

  group('faixa de specVersion e formas tipadas', () {
    Map<String, dynamic> content({
      required int specVersion,
      Map<String, dynamic>? root,
      Map<String, dynamic>? safeArea,
    }) => {
      'specVersion': specVersion,
      'kind': 'content',
      'id': 'ct',
      'name': 'N',
      'slug': 'n',
      'root': ?root,
      'safeArea': ?safeArea,
    };

    Map<String, dynamic> textNode(Object? data) => {
      'id': 'nd_text',
      'type': 'text',
      'props': {'data': data},
    };

    test('specVersion 1 e 2 são aceitas', () {
      for (final version in [kOldestSpecVersion, kLatestSpecVersion]) {
        final result = parseContentSpec(content(specVersion: version));
        expect(result.isRight(), isTrue, reason: '$version: $result');
        expect(result.getRight().toNullable()!.specVersion, version);
      }
    });

    test('specVersion 0 e 3 são recusadas com a faixa na mensagem', () {
      for (final version in [0, 3]) {
        final error = parseContentSpec(
          content(specVersion: version),
        ).getLeft().toNullable();
        expect(
          error?.message,
          'specVersion $version não suportada (suportadas: 1 a 2)',
        );
      }
    });

    test(r'$theme em root.props com v1 é recusado', () {
      final error = parseContentSpec(
        content(
          specVersion: 1,
          root: {
            'id': 'nd_root',
            'type': 'container',
            'props': {
              'color': {r'$theme': 'primary'},
            },
          },
        ),
      ).getLeft().toNullable();

      expect(error?.message, startsWith('root.props.color: '));
      expect(error!.message, contains('specVersion 2 ou maior (o spec é 1)'));
    });

    test('erro num filho aponta o caminho do filho', () {
      final error = parseContentSpec(
        content(
          specVersion: 2,
          root: {
            'id': 'nd_root',
            'type': 'column',
            'children': [
              textNode({
                r'$bind': {'source': 'pageParam', 'path': 'user.name'},
              }),
            ],
          },
        ),
      ).getLeft().toNullable();

      expect(
        error?.message,
        'root.children[0].props.data: '
        'binding em prop obrigatória exige fallback',
      );
    });

    test(r'safeArea.enabled com $theme é recusado em v2', () {
      final error = parseContentSpec(
        content(
          specVersion: 2,
          safeArea: {
            'enabled': {r'$theme': 'x'},
          },
        ),
      ).getLeft().toNullable();

      expect(
        error?.message,
        'safeArea.enabled: a prop não aceita token do tema nem binding',
      );
    });

    test(r'$bind válido chega cru em SduiNode.properties', () {
      final data = {
        r'$bind': {
          'source': 'pageParam',
          'path': 'user.name',
          'fallback': 'Visitante',
        },
      };

      final spec = parseContentSpec(
        content(specVersion: 2, root: textNode(data)),
      ).getRight().toNullable();

      expect(spec, isNotNull);
      expect(spec!.root!.properties, {'data': data});
      expect(spec.root!.properties['data'], same(data));
    });
  });
}
