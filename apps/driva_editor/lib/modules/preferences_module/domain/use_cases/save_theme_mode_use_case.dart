import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/domain/repositories/preferences_repository.dart';
import 'package:fpdart/fpdart.dart';

class SaveThemeModeUseCase {
  const SaveThemeModeUseCase({required this.repository});
  final PreferencesRepository repository;

  Future<Either<Failure, Unit>> call(AppThemeMode mode) =>
      repository.saveThemeMode(mode);
}
