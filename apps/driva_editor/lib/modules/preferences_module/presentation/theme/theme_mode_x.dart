import 'package:flutter/material.dart';

import '../../domain/entities/app_theme_mode.dart';

/// Ponte do [AppThemeMode] (domínio, Dart puro) para o `ThemeMode` do Flutter.
/// Fica na presentation — a única camada que pode falar `package:flutter`.
extension AppThemeModeX on AppThemeMode {
  ThemeMode get materialThemeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
