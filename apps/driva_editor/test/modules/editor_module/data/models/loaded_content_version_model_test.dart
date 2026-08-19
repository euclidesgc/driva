import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/loaded_content_version_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  Map<String, dynamic> specJson({int specVersion = kSpecVersion}) => {
    'specVersion': specVersion,
    'kind': 'content',
    'id': 'ct_1',
    'name': 'Home',
    'slug': 'home',
  };

  Map<String, dynamic> validMap({int specVersion = kSpecVersion}) => {
    'version': 2,
    'spec': specJson(specVersion: specVersion),
    'createdAt': DateTime(2026, 8, 16, 10, 30),
    'note': 'Ajuste no banner',
    'createdBy': 'user_1',
  };

  group('tryParse', () {
    test('mapa válido devolve a versão com o spec já parseado', () {
      final result = LoadedContentVersionModel.tryParse(validMap());

      final loaded = result.getRight().toNullable();
      expect(loaded, isNotNull);
      expect(loaded!.version, 2);
      expect(loaded.spec.id, 'ct_1');
      expect(loaded.spec.slug, 'home');
      expect(loaded.createdAt, DateTime(2026, 8, 16, 10, 30));
      expect(loaded.note, 'Ajuste no banner');
      expect(loaded.createdBy, 'user_1');
    });

    test('note e createdBy ausentes (versão sem autor) são nulos', () {
      final map = validMap()
        ..remove('note')
        ..remove('createdBy');

      final result = LoadedContentVersionModel.tryParse(map);

      final loaded = result.getRight().toNullable();
      expect(loaded, isNotNull);
      expect(loaded!.note, isNull);
      expect(loaded.createdBy, isNull);
    });

    test(
      'JSON inválido (campo obrigatório ausente) vira ValidationFailure',
      () {
        final map = validMap()..remove('version');

        final result = LoadedContentVersionModel.tryParse(map);

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      },
    );

    test('JSON inválido (tipo incompatível) vira ValidationFailure', () {
      final map = validMap()..['createdAt'] = 42;

      final result = LoadedContentVersionModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('spec ausente vira ValidationFailure', () {
      final map = validMap()..remove('spec');

      final result = LoadedContentVersionModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('spec nulo vira ValidationFailure', () {
      final map = validMap()..['spec'] = null;

      final result = LoadedContentVersionModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('specVersion incompatível vira ValidationFailure', () {
      final map = validMap(specVersion: kSpecVersion + 1);

      final result = LoadedContentVersionModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });
}
