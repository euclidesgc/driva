part of 'theme_cubit.dart';

final class ThemeState extends Equatable {
  const ThemeState(this.mode);

  final AppThemeMode mode;

  @override
  List<Object?> get props => [mode];
}
