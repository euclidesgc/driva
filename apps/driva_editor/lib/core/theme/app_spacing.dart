/// Invariante ao tema (um espaçamento de 16 é 16 em claro ou escuro), por isso
/// são `static const` — consumidos direto (`AppSpacing.s16`), sem
/// `BuildContext`.
/// Calibrada pelos valores já usados no código (não inventada): trocar o ritmo
/// de espaçamento da app é mexer só aqui.
///
/// Nomeados pelo valor (`sN`) porque a distribuição real não cabe numa escala
/// t-shirt limpa (mistura grid de 4 com meios-passos 6/10/14). O ganho do gate
/// é a centralização; o número no nome é honesto quanto ao valor atual.
abstract final class AppSpacing {
  static const double none = 0;
  static const double s1 = 1;
  static const double s2 = 2;
  static const double s3 = 3;
  static const double s4 = 4;
  static const double s5 = 5;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s15 = 15;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;

  // Faixa "grande": paddings de seção/página e folga de scroll do canvas.
  // Não são ritmo de UI densa — são respiro de layout (empty states, margens
  // de página, boundary do InteractiveViewer).
  static const double s34 = 34;
  static const double s64 = 64;
  static const double s70 = 70;
  static const double s80 = 80;
  static const double s90 = 90;
}
