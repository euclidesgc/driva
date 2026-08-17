import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_version_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validMap = {
    'version': 2,
    'createdAt': DateTime(2026, 8, 16, 10, 30),
    'note': 'Ajuste no banner',
    'createdBy': 'user_1',
  };

  group('tryParse', () {
    test('mapa válido devolve a versão equivalente', () {
      final result = ContentVersionModel.tryParse(validMap);

      final version = result.getRight().toNullable();
      expect(version, isNotNull);
      expect(
        version!.props,
        ContentVersion(
          version: 2,
          createdAt: DateTime(2026, 8, 16, 10, 30),
          note: 'Ajuste no banner',
          createdBy: 'user_1',
        ).props,
      );
    });

    test(
      'note e createdBy ausentes (nunca publicado por usuário) são nulos',
      () {
        final map = Map<String, dynamic>.from(validMap)
          ..remove('note')
          ..remove('createdBy');

        final result = ContentVersionModel.tryParse(map);

        final version = result.getRight().toNullable();
        expect(version, isNotNull);
        expect(version!.note, isNull);
        expect(version.createdBy, isNull);
      },
    );

    test('campo obrigatório ausente vira ValidationFailure', () {
      final map = Map<String, dynamic>.from(validMap)..remove('version');

      final result = ContentVersionModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('tipo incompatível (corrompido) vira ValidationFailure', () {
      final map = Map<String, dynamic>.from(validMap)..['version'] = 'dois';

      final result = ContentVersionModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });
}
