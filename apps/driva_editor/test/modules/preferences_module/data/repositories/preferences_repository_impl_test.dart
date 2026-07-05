import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/data/repositories/preferences_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'preferences.theme_mode';

  Future<PreferencesRepositoryImpl> buildWith(
    Map<String, Object> initial,
  ) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return PreferencesRepositoryImpl(prefs);
  }

  group('getThemeMode', () {
    test('sem valor salvo devolve system (padrão), nunca falha', () async {
      final repo = await buildWith({});

      final result = await repo.getThemeMode();

      expect(result.getRight().toNullable(), AppThemeMode.system);
    });

    test('lê o valor persistido', () async {
      final repo = await buildWith({key: 'dark'});

      final result = await repo.getThemeMode();

      expect(result.getRight().toNullable(), AppThemeMode.dark);
    });

    test('valor corrompido vira ValidationFailure', () async {
      final repo = await buildWith({key: 'roxo'});

      final result = await repo.getThemeMode();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });

  group('saveThemeMode', () {
    test('persiste e relê o mesmo modo', () async {
      final repo = await buildWith({});

      final saved = await repo.saveThemeMode(AppThemeMode.light);
      final read = await repo.getThemeMode();

      expect(saved.isRight(), isTrue);
      expect(read.getRight().toNullable(), AppThemeMode.light);
    });
  });
}
