import 'package:flutter/material.dart';

import 'editor_colors.dart';

/// Tema base do editor, derivado do protótipo visual
/// (`docs/web-prototipe/Driva Builder.dc.html`).
///
/// As cores semânticas vivem em [EditorColors] (theme-aware, light/dark);
/// aqui só permanece a laranja da marca, idêntica nos dois temas.
abstract final class AppTheme {
  /// Laranja Driva — accent primário (seleção, ferramentas ativas, CTAs).
  static const Color primary = Color(0xFFE8602C);

  static ThemeData get light => _build(Brightness.light, EditorColors.light);

  static ThemeData get dark => _build(Brightness.dark, EditorColors.dark);

  static ThemeData _build(Brightness brightness, EditorColors colors) {
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

    return base.copyWith(
      extensions: [colors],
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
          borderRadius: const BorderRadius.all(Radius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.inkPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.panelAlt,
        hintStyle: TextStyle(color: colors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
    );
  }
}
