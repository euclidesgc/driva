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
}
