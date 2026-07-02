import 'package:flutter/material.dart';

/// Base theme of the editor, extracted from the visual prototype
/// (`docs/web-prototipe/Driva Builder.dc.html`).
///
/// The design system evolves here: panels are white surfaces over a soft
/// gray canvas, with the Driva orange as the single accent color.
abstract final class AppTheme {
  // --- Palette (values lifted from the prototype CSS) ---

  /// Driva orange — primary accent (selection, active tools, CTAs).
  static const Color primary = Color(0xFFE8602C);

  /// Soft orange tint — background of selected/active items.
  static const Color primaryTint = Color(0xFFFFF0EB);

  /// Main text color (near-black slate).
  static const Color ink = Color(0xFF3A3F47);

  /// Secondary text (labels, descriptions).
  static const Color inkSecondary = Color(0xFF6B7280);

  /// Muted text (hints, placeholders, disabled).
  static const Color inkMuted = Color(0xFF9AA0A8);

  /// Default border/divider color of panels and cards.
  static const Color border = Color(0xFFE6E8EB);

  /// App canvas background (behind the panels).
  static const Color canvas = Color(0xFFEEF0F2);

  /// Panel/card surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Success (e.g. "salvo").
  static const Color success = Color(0xFF16A34A);

  // --- Theme ---

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryTint,
      onPrimaryContainer: primary,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: inkSecondary,
      outline: border,
      outlineVariant: border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Public Sans',
    );

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
    );
  }
}
