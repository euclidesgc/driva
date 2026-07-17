import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/domain/repositories/preferences_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetThemeModeUseCase {
  const GetThemeModeUseCase({required this.repository});
  final PreferencesRepository repository;

  Future<Either<Failure, AppThemeMode>> call() => repository.getThemeMode();
}
