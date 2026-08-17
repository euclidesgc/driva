import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_versions_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParse', () {
    test('envelope válido devolve os itens na ordem e o nextCursor', () {
      final map = {
        'data': [
          {'version': 2, 'createdAt': DateTime(2026, 8, 16)},
          {'version': 1, 'createdAt': DateTime(2026, 8, 15)},
        ],
        'nextCursor': 'cursor-abc',
      };

      final result = ContentVersionsPageModel.tryParse(map);

      final page = result.getRight().toNullable();
      expect(page, isNotNull);
      expect(page!.items.map((v) => v.version), [2, 1]);
      expect(page.nextCursor, 'cursor-abc');
    });

    test('nextCursor nulo (última página) parseia normalmente', () {
      final map = {
        'data': [
          {'version': 1, 'createdAt': DateTime(2026, 8, 15)},
        ],
        'nextCursor': null,
      };

      final result = ContentVersionsPageModel.tryParse(map);

      expect(result.getRight().toNullable()?.nextCursor, isNull);
    });

    test('data ausente vira ValidationFailure', () {
      final map = {'nextCursor': null};

      final result = ContentVersionsPageModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('item da lista corrompido propaga o ValidationFailure do item', () {
      final map = {
        'data': [
          {'version': 'não é número', 'createdAt': DateTime(2026, 8, 15)},
        ],
        'nextCursor': null,
      };

      final result = ContentVersionsPageModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });
}
