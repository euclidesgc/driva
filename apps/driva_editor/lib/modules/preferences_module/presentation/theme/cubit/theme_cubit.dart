import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_theme_mode.dart';
import '../../../domain/use_cases/use_cases.dart';

part 'theme_state.dart';

/// Governa a preferência de tema acima do `MaterialApp`. Carrega a opção
/// persistida no início e a atualiza (persistindo) quando o usuário alterna.
class ThemeCubit extends Cubit<ThemeState> {
  final GetThemeModeUseCase getThemeMode;
  final SaveThemeModeUseCase saveThemeMode;

  ThemeCubit({required this.getThemeMode, required this.saveThemeMode})
    : super(const ThemeState(AppThemeMode.system));

  /// Lê a preferência salva. Uma falha de leitura mantém o padrão (system) —
  /// o tema nunca é motivo para a app não subir.
  Future<void> load() async {
    final result = await getThemeMode();
    if (isClosed) return;
    result.fold(
      (_) => emit(const ThemeState(AppThemeMode.system)),
      (mode) => emit(ThemeState(mode)),
    );
  }

  /// Aplica na hora (UI responde já) e persiste em seguida.
  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state.mode) return;
    emit(ThemeState(mode));
    await saveThemeMode(mode);
  }
}
