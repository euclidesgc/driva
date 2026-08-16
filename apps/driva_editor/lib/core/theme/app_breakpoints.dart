/// Limiares de largura que governam o comportamento por faixa das telas de
/// **navegação** (home de projetos, detalhe do projeto, categorias, lista de
/// conteúdos). Mesmos números do item 30 (Material 3), mas um vocabulário
/// próprio do editor: nunca importa o enum de faixa do `sdui_core` — chrome
/// da ferramenta e faixa do spec do cliente são coisas diferentes, e
/// `editor_module` não consulta este arquivo (D1: o editor mira desktop).
abstract final class AppBreakpoints {
  static const double compact = 600;

  static bool isCompact(double width) => width < compact;
}
