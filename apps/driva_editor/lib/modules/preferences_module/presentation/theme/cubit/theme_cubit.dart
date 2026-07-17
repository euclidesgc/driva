import 'package:bloc/bloc.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/domain/use_cases/use_cases.dart';
import 'package:equatable/equatable.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required this.getThemeMode, required this.saveThemeMode})
    : super(const ThemeState(AppThemeMode.system));
  final GetThemeModeUseCase getThemeMode;
  final SaveThemeModeUseCase saveThemeMode;

  Future<void> load() async {
    final result = await getThemeMode();
    if (isClosed) return;
    result.fold(
      (_) => emit(const ThemeState(AppThemeMode.system)),
      (mode) => emit(ThemeState(mode)),
    );
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state.mode) return;
    emit(ThemeState(mode));
    await saveThemeMode(mode);
  }
}
