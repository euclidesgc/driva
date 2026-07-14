import 'package:flutter/material.dart';

import 'app_durations.dart';
import 'app_radii.dart';
import 'device_mock_colors.dart';
import 'editor_colors.dart';
import 'syntax_colors.dart';

/// Base theme of the editor.
///
/// The design system evolves here: panels are surfaces over a soft canvas
/// backdrop, with the Driva orange as the single accent color. Theme-aware
/// tokens live in [EditorColors] (registered as a [ThemeExtension]); only the
/// brand orange stays a plain constant, since it is identical in both themes.
abstract final class AppTheme {
  /// Driva orange — primary accent (selection, active tools, CTAs).
  /// Same value in light and dark.
  static const Color primary = Color(0xFFE8602C);

  static ThemeData get light => _build(EditorColors.light, Brightness.light);

  static ThemeData get dark => _build(EditorColors.dark, Brightness.dark);

  static ThemeData _build(EditorColors colors, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: colors.primaryTint,
          onPrimaryContainer: primary,
          surface: colors.panel,
          onSurface: colors.inkPrimary,
          onSurfaceVariant: colors.inkSecondary,
          outline: colors.border,
          outlineVariant: colors.border,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Public Sans',
    );

    final isDark = brightness == Brightness.dark;
    return base.copyWith(
      extensions: [
        colors,
        isDark ? DeviceMockColors.dark : DeviceMockColors.light,
        isDark ? SyntaxColors.dark : SyntaxColors.light,
      ],
      scaffoldBackgroundColor: colors.canvasBackdrop,
      dividerColor: colors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.panel,
        foregroundColor: colors.inkPrimary,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: colors.border)),
      ),
      cardTheme: CardThemeData(
        color: colors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.border),
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.r12)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colors.inkPrimary,
        displayColor: colors.inkPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.r8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.inkPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.r8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.panelAlt,
        hintStyle: TextStyle(color: colors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.r8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.r8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.r8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      tooltipTheme: const TooltipThemeData(waitDuration: AppDurations.slow),
    );
  }
}
