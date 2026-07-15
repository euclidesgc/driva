/// Invariante ao tema, por isso `static const`. Só o tamanho — peso e cor são
/// aplicados no uso (cor vem de [EditorColors]). Calibrada pelos tamanhos já
/// usados: micro/rótulos densos (10–12), corpo padrão (13), destaque (20).
abstract final class AppTypography {
  static const double xs = 10;

  static const double sm = 11;

  static const double md = 12;

  static const double base = 13;

  static const double xl = 20;
}
