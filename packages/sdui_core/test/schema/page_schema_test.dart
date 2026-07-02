import 'dart:convert';
import 'dart:io';

import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _loadFixture(String name) {
  // Funciona rodando da raiz do workspace ou de dentro do pacote.
  final local = File('test/fixtures/$name');
  final file = local.existsSync()
      ? local
      : File('packages/sdui_core/test/fixtures/$name');
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
}

void main() {
  group('parsePageSpec', () {
    test('aceita a página da fixture e preserva a árvore', () {
      final result = parsePageSpec(_loadFixture('page_valid.json'));

      final page = result.getRight().toNullable();
      expect(page, isNotNull, reason: result.toString());
      expect(page!.id, 'pg_home_promo');
      expect(page.screenTarget, 'home');
      expect(page.root.type, 'column');
      expect(page.root.children, hasLength(5));

      final banner = page.root.children.first;
      expect(banner.type, 'container');
      expect(banner.properties['color'], '#6C4CF1');
      expect(banner.child?.type, 'text');

      final cta = page.root.children.last;
      expect(cta.events['onPressed'], isA<List<dynamic>>());
    });

    test('roundtrip: toJson de uma página parseada re-parseia igual', () {
      final page = parsePageSpec(_loadFixture('page_valid.json'))
          .getRight()
          .toNullable()!;
      final reparsed = parsePageSpec(page.toJson()).getRight().toNullable();

      expect(reparsed, equals(page));
    });

    test('rejeita specVersion desconhecida', () {
      final json = _loadFixture('page_valid.json')..['specVersion'] = 99;

      final error = parsePageSpec(json).getLeft().toNullable();

      expect(error, isNotNull);
      expect(error!.message, contains('specVersion'));
    });

    test('rejeita kind diferente de page', () {
      final json = _loadFixture('page_valid.json')..['kind'] = 'widget';

      expect(parsePageSpec(json).isLeft(), isTrue);
    });

    test('rejeita root que não é column', () {
      final json = _loadFixture('page_valid.json');
      json['root'] = {'id': 'nd_root', 'type': 'row'};

      final error = parsePageSpec(json).getLeft().toNullable();

      expect(error!.message, contains('column'));
    });

    test('rejeita nó com tipo fora do catálogo', () {
      final json = _loadFixture('page_valid.json');
      json['root'] = {
        'id': 'nd_root',
        'type': 'column',
        'children': [
          {'id': 'nd_x', 'type': 'carousel3d'},
        ],
      };

      final error = parsePageSpec(json).getLeft().toNullable();

      expect(error!.message, contains('carousel3d'));
    });

    test('rejeita folha com filhos (contrato de slot)', () {
      final json = _loadFixture('page_valid.json');
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

      final error = parsePageSpec(json).getLeft().toNullable();

      expect(error!.message, contains('folha'));
    });

    test('rejeita nó sem id', () {
      final json = _loadFixture('page_valid.json');
      json['root'] = {
        'id': 'nd_root',
        'type': 'column',
        'children': [
          {'type': 'text'},
        ],
      };

      expect(parsePageSpec(json).isLeft(), isTrue);
    });
  });
}
