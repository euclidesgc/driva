import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/app_theme_mode.dart';

abstract interface class PreferencesRepository {
  Future<Either<Failure, AppThemeMode>> getThemeMode();

  Future<Either<Failure, Unit>> saveThemeMode(AppThemeMode mode);
}
