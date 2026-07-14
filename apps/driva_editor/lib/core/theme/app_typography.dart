/// Escala tipográfica do editor (tamanhos de fonte).
///
/// Invariante ao tema, por isso `static const`. Só o tamanho — peso e cor são
/// aplicados no uso (cor vem de [EditorColors]). Calibrada pelos tamanhos já
/// usados: micro/rótulos densos (10–12), corpo padrão (13), destaque (20).
abstract final class AppTypography {
  /// Micro-texto (badges, tags, gutters). `fontSize: 10`.
  static const double xs = 10;

  /// Rótulos e legendas pequenas. `fontSize: 11`.
  static const double sm = 11;

  /// Rótulos densos e chips. `fontSize: 12`.
  static const double md = 12;

  /// Corpo padrão do editor (o mais comum). `fontSize: 13`.
  static const double base = 13;

  /// Destaque (iniciais de capa, títulos curtos). `fontSize: 20`.
  static const double xl = 20;
}
