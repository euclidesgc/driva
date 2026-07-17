import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/data/models/theme_mode_model.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/domain/repositories/preferences_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl(this.prefs);
  static const _themeModeKey = 'preferences.theme_mode';

  final SharedPreferences prefs;

  @override
  Future<Either<Failure, AppThemeMode>> getThemeMode() async {
    try {
      final raw = prefs.getString(_themeModeKey);
      if (raw == null) return const Right(AppThemeMode.system);
      return ThemeModeModel.tryParse(raw);
    } on Exception catch (_) {
      return const Left(
        UnexpectedFailure('Falha ao ler a preferência de tema.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> saveThemeMode(AppThemeMode mode) async {
    try {
      await prefs.setString(_themeModeKey, ThemeModeModel.encode(mode));
      return const Right(unit);
    } on Exception catch (_) {
      return const Left(
        UnexpectedFailure('Falha ao salvar a preferência de tema.'),
      );
    }
  }
}
