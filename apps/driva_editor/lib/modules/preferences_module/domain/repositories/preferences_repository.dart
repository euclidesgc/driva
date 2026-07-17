import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PreferencesRepository {
  Future<Either<Failure, AppThemeMode>> getThemeMode();

  Future<Either<Failure, Unit>> saveThemeMode(AppThemeMode mode);
}
