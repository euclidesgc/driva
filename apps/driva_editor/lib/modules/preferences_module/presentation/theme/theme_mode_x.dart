import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:flutter/material.dart';

extension AppThemeModeX on AppThemeMode {
  ThemeMode get materialThemeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
