import 'dart:convert';
import 'dart:io';

import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/data/models/published_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _envelope(Map<String, dynamic> spec) => {
  'id': 'c1',
  'name': 'Vitrine',
  'slug': 'vitrine',
  'updatedAt': '2026-08-14T12:00:00.000Z',
  'spec': spec,
};

Map<String, dynamic> _minimalSpec({Map<String, dynamic>? root}) => {
  'specVersion': 1,
  'kind': 'content',
  'id': 'c1',
  'name': 'Vitrine',
  'slug': 'vitrine',
  'root': ?root,
};

void main() {
  group('PublishedContentModel', () {
    test('lê o envelope e devolve o spec parseado pelo kernel', () {
      final result = PublishedContentModel.tryParse(
        _envelope(
          _minimalSpec(
            root: {
              'id': 'n1',
              'type': 'text',
              'props': {'data': 'olá'},
            },
          ),
        ),
        etag: '"c1-1"',
      );

      final content = result.getRight().toNullable();
      expect(content, isNotNull);
      expect(content!.spec.slug, 'vitrine');
      expect(content.spec.root?.type, 'text');
      expect(content.etag, '"c1-1"');
    });

    test('aceita conteúdo sem root (página que nasceu vazia)', () {
      final result = PublishedContentModel.tryParse(_envelope(_minimalSpec()));

      expect(result.getRight().toNullable()?.spec.root, isNull);
    });

    test('recusa envelope sem os campos da API', () {
      final result = PublishedContentModel.tryParse({'spec': _minimalSpec()});

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('recusa spec que o kernel não valida', () {
      final result = PublishedContentModel.tryParse(
        _envelope({'specVersion': 1, 'kind': 'content', 'id': 'c1'}),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('recusa nó fora do catálogo', () {
      final result = PublishedContentModel.tryParse(
        _envelope(
          _minimalSpec(
            root: {
              'id': 'n1',
              'type': 'inventado',
              'props': <String, dynamic>{},
            },
          ),
        ),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('o spec de vitrine das evidências passa pelo kernel', () {
      final file = File('../../docs/13-loop-sdui/evidencias/vitrine_spec.json');
      final spec = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final result = PublishedContentModel.tryParse(_envelope(spec));

      final content = result.getRight().toNullable();
      final failure = result.getLeft().toNullable();
      expect(content, isNotNull, reason: failure?.message);
      expect(content!.spec.root?.type, 'listView');
      expect(content.spec.root?.children.length, 4);
    });
  });
}
