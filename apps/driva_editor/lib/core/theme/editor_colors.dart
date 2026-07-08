import 'package:flutter/material.dart';

/// Tokens de cor do editor que reagem ao tema (claro/escuro).
///
/// Substituem as antigas constantes `static const` de `AppTheme`, que não
/// mudavam com o tema e deixavam painéis/labels claros no dark. Cada token
/// resolve para o valor certo via `Theme.of(context).extension<EditorColors>()`.
///
/// Paleta calibrada para WCAG AA (texto >= 4.5:1; muted >= 4.0:1).
class EditorColors extends ThemeExtension<EditorColors> {
  const EditorColors({
    required this.canvasBackdrop,
    required this.panel,
    required this.panelAlt,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkMuted,
    required this.border,
    required this.primaryTint,
    required this.success,
  });

  /// Fundo atrás do mock e do scaffold.
  final Color canvasBackdrop;

  /// Painéis, appbar e superfície de card.
  final Color panel;

  /// Inputs, dropdowns e hover.
  final Color panelAlt;

  /// Texto principal.
  final Color inkPrimary;

  /// Texto secundário (labels, descrições).
  final Color inkSecondary;

  /// Texto apagado (hints, placeholders, desabilitado).
  final Color inkMuted;

  /// Bordas e divisores.
  final Color border;

  /// Fundo do item selecionado/ativo.
  final Color primaryTint;

  /// Feedback de sucesso (ex.: "salvo").
  final Color success;

  static const EditorColors light = EditorColors(
    canvasBackdrop: Color(0xFFEEF0F2),
    panel: Color(0xFFFFFFFF),
    panelAlt: Color(0xFFF7F8FA),
    inkPrimary: Color(0xFF242A33),
    inkSecondary: Color(0xFF5B6472),
    inkMuted: Color(0xFF7A828F),
    border: Color(0xFFE4E7EC),
    primaryTint: Color(0xFFFFF0EB),
    success: Color(0xFF16A34A),
  );

  static const EditorColors dark = EditorColors(
    canvasBackdrop: Color(0xFF0F1216),
    panel: Color(0xFF191E25),
    panelAlt: Color(0xFF222A33),
    inkPrimary: Color(0xFFE9EBEF),
    inkSecondary: Color(0xFFB7BEC9),
    inkMuted: Color(0xFF8B95A3),
    border: Color(0xFF2C333D),
    primaryTint: Color(0xFF33231B),
    success: Color(0xFF3FBE6B),
  );

  @override
  EditorColors copyWith({
    Color? canvasBackdrop,
    Color? panel,
    Color? panelAlt,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkMuted,
    Color? border,
    Color? primaryTint,
    Color? success,
  }) {
    return EditorColors(
      canvasBackdrop: canvasBackdrop ?? this.canvasBackdrop,
      panel: panel ?? this.panel,
      panelAlt: panelAlt ?? this.panelAlt,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      border: border ?? this.border,
      primaryTint: primaryTint ?? this.primaryTint,
      success: success ?? this.success,
    );
  }

  @override
  EditorColors lerp(covariant EditorColors? other, double t) {
    if (other == null) return this;
    return EditorColors(
      canvasBackdrop: Color.lerp(canvasBackdrop, other.canvasBackdrop, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelAlt: Color.lerp(panelAlt, other.panelAlt, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
