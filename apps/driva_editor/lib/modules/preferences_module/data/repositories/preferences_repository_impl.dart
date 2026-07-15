import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../models/theme_mode_model.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  static const _themeModeKey = 'preferences.theme_mode';

  final SharedPreferences prefs;
  const PreferencesRepositoryImpl(this.prefs);

  @override
  Future<Either<Failure, AppThemeMode>> getThemeMode() async {
    try {
      final raw = prefs.getString(_themeModeKey);
      if (raw == null) return const Right(AppThemeMode.system);
      return ThemeModeModel.tryParse(raw);
    } catch (_) {
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
    } catch (_) {
      return const Left(
        UnexpectedFailure('Falha ao salvar a preferência de tema.'),
      );
    }
  }
}
