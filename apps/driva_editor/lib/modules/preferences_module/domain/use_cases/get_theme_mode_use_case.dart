import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/preferences_repository.dart';

class GetThemeModeUseCase {
  final PreferencesRepository repository;
  const GetThemeModeUseCase({required this.repository});

  Future<Either<Failure, AppThemeMode>> call() => repository.getThemeMode();
}
