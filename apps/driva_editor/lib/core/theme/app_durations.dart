/// Durações de animação/interação do editor.
///
/// Invariantes ao tema, por isso `static const`. Calibradas pelas durações já
/// usadas: micro-transições até o wait de tooltip.
abstract final class AppDurations {
  /// Micro-transição (realce de hover, fade curto). 120ms.
  static const Duration micro = Duration(milliseconds: 120);

  /// Transição rápida. 160ms.
  static const Duration fast = Duration(milliseconds: 160);

  /// Transição breve. 200ms.
  static const Duration quick = Duration(milliseconds: 200);

  /// Transição padrão (a mais comum). 300ms.
  static const Duration normal = Duration(milliseconds: 300);

  /// Espera antes de mostrar tooltip. 400ms.
  static const Duration slow = Duration(milliseconds: 400);
}
