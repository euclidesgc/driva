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

  // --- Dark palette ---
  //
  // Mesma marca (o laranja), agora sobre uma base escura: canvas quase-preto
  // com painéis em cinza-carvão levemente mais claros, para os cards
  // "flutuarem" como no claro. Tinta clara para o texto, na hierarquia inversa.

  /// Orange tint over the dark surface (background of selected/active items).
  static const Color primaryTintDark = Color(0xFF3A241C);

  /// Main text color on dark (near-white).
  static const Color inkDark = Color(0xFFE6E8EB);

  /// Secondary text on dark.
  static const Color inkSecondaryDark = Color(0xFFA6ADB6);

  /// Muted text on dark (hints, placeholders, disabled).
  static const Color inkMutedDark = Color(0xFF6B7280);

  /// Default border/divider color on dark.
  static const Color borderDark = Color(0xFF2C3138);

  /// App canvas background on dark (behind the panels).
  static const Color canvasDark = Color(0xFF14171A);

  /// Panel/card surface on dark.
  static const Color surfaceDark = Color(0xFF1E2226);

  // --- Theme ---

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
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
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: primaryTintDark,
          onPrimaryContainer: primary,
          surface: surfaceDark,
          onSurface: inkDark,
          onSurfaceVariant: inkSecondaryDark,
          outline: borderDark,
          outlineVariant: borderDark,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Public Sans',
    );

    return base.copyWith(
      scaffoldBackgroundColor: canvasDark,
      dividerColor: borderDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: inkDark,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: borderDark)),
      ),
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderDark),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: inkDark,
        displayColor: inkDark,
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
          foregroundColor: inkDark,
          side: const BorderSide(color: borderDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: const TextStyle(color: inkMutedDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
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
