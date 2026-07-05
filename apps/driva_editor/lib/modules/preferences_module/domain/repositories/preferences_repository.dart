import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/app_theme_mode.dart';

/// Contrato da camada de preferências locais do usuário.
///
/// Introduzido pelo tema (item 3 do roadmap) como base reutilizável — o
/// offline-first (item 17) reaproveita esta mesma camada de armazenamento local.
abstract interface class PreferencesRepository {
  /// Lê a preferência de tema. Ausência de valor salvo devolve
  /// [AppThemeMode.system] (o padrão), nunca uma falha.
  Future<Either<Failure, AppThemeMode>> getThemeMode();

  Future<Either<Failure, Unit>> saveThemeMode(AppThemeMode mode);
}
