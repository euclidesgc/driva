import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/app_theme_mode.dart';

/// (De)serialização do [AppThemeMode] para a chave de armazenamento local.
///
/// A forma persistida é o `name` do enum (`system`/`light`/`dark`), validado
/// por zard na leitura — um valor corrompido vira `ValidationFailure`, nunca um
/// cast cru estourando.
abstract final class ThemeModeModel {
  static final _schema = z.$enum(['system', 'light', 'dark']);

  static String encode(AppThemeMode mode) => mode.name;

  static Either<Failure, AppThemeMode> tryParse(String raw) {
    final result = _schema.safeParse(raw);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    return Right(AppThemeMode.values.firstWhere((m) => m.name == result.data));
  }
}
