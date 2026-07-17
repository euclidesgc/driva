import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

abstract final class ThemeModeModel {
  static final ZEnum _schema = z.$enum(['system', 'light', 'dark']);

  static String encode(AppThemeMode mode) => mode.name;

  static Either<Failure, AppThemeMode> tryParse(String raw) {
    final result = _schema.safeParse(raw);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    return Right(AppThemeMode.values.firstWhere((m) => m.name == result.data));
  }
}
