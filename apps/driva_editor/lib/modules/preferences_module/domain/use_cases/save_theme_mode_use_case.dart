import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/preferences_repository.dart';

class SaveThemeModeUseCase {
  final PreferencesRepository repository;
  const SaveThemeModeUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(AppThemeMode mode) =>
      repository.saveThemeMode(mode);
}
