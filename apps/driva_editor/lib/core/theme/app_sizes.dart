import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';

/// Larguras de componente que não cabem no ritmo genérico de espaçamento —
/// medidas contra a composição real, não um valor de design abstrato.
abstract final class AppSizes {
  static const double categoryTreePanelWidth = 272;

  /// Largura da faixa fina de ícones do painel colapsado (D2, F5): o
  /// `IconButton` padrão do Material 3 mantém [AppIconSizes.s40] de área de
  /// toque mesmo com um ícone [AppIconSizes.s18] — é essa pegada que a faixa
  /// respira com [AppSpacing.s8] de cada lado, não um valor abstrato.
  static const double panelRailWidth = AppIconSizes.s40 + (AppSpacing.s8 * 2);

  /// Largura fixa do campo de busca no cabeçalho do painel de conteúdos, em
  /// faixa larga (linha única, ao lado da ordenação e do modo de
  /// visualização).
  static const double contentPanelSearchWidth = 220;

  /// Abaixo desta largura de janela, o cabeçalho do painel de conteúdos
  /// (busca + ordenação + modo de visualização, numa linha ao lado da barra
  /// de categorias fixa) para de caber — soma [categoryTreePanelWidth] + 1
  /// (divisor) + 48 (padding do cabeçalho) + [contentPanelSearchWidth] + 10
  /// (vão) + 244 (ordenação + modo, medido). Não é breakpoint — é o limiar
  /// em que esta composição específica para de caber (mesmo papel de
  /// `topBarActionsFitWidth`, F3); não governa mais nada.
  static const double contentPanelWideHeaderFitWidth =
      categoryTreePanelWidth +
      1 +
      (AppSpacing.s24 * 2) +
      contentPanelSearchWidth +
      AppSpacing.s10 +
      244;

  /// Largura de conteúdo dos diálogos de formulário mais simples (conteúdo,
  /// categoria, mover conteúdo).
  static const double formDialogWidth = 380;

  /// Largura de conteúdo do diálogo de projeto — tem capa e descrição mais
  /// longa, por isso é mais largo que [formDialogWidth].
  static const double wideFormDialogWidth = 460;

  /// Altura da lista rolável do diálogo de histórico de versões (item 24) —
  /// sem teto, o `AlertDialog` cresceria com a paginação e estouraria a
  /// tela em conteúdos com muitas versões.
  static const double versionHistoryListHeight = 360;

  /// Folga que a lista reserva no rodapé enquanto o `LoadingMoreFooter`
  /// flutua sobre ela: sem isso o último item fica encoberto e o usuário não
  /// consegue rolar até ele.
  static const double loadingMoreFooterInset = 56;

  /// Largura de conteúdo do histórico de versões (item 50) — mais largo que
  /// [formDialogWidth] porque cada linha ganhou três ações (`Ver`,
  /// `Comparar`, `Carregar no rascunho`) ao lado dos metadados, e 380px as
  /// espremia.
  static const double versionHistoryDialogWidth = 560;

  /// Largura do diálogo de revisão de versão (item 50) no desktop: espaço
  /// para o cabeçalho de metadados e o snapshot `SduiView` sem que ele
  /// pareça um recorte apertado do canvas real.
  static const double versionReviewDialogWidth = 720;

  /// Abaixo desta largura de janela, `VersionReviewDialog` deixa de caber
  /// como diálogo flutuante sem espremer o snapshot e passa a ocupar a tela
  /// inteira (mesmo papel de [topBarActionsFitWidth]/
  /// [contentPanelWideHeaderFitWidth] para esta composição).
  static const double versionReviewDialogFitWidth = 900;

  /// Altura do snapshot somente leitura dentro de `VersionReviewDialog` no
  /// desktop — teto para o `AlertDialog` não crescer com o tamanho do spec
  /// histórico; no compacto o diálogo ocupa a tela e o snapshot usa a altura
  /// disponível.
  static const double versionSnapshotPreviewHeight = 420;

  /// O orçamento horizontal que `DialogContentWidth` precisa descontar da
  /// tela: o `insetPadding` padrão do Material (`AlertDialog`) é 40px de
  /// cada lado — 80 no total. Só isso; o `contentPadding` interno do diálogo
  /// já está fora do que `DialogContentWidth` mede (ele embrulha o
  /// `content`, que já está dentro do `contentPadding`).
  static const double dialogInsetBudget = 80;

  /// Largura mínima do centro (canvas) do editor abaixo da qual o `Expanded`
  /// deixa de fazer sentido — o mock precisa de espaço pra existir, não só
  /// de um pixel de sobra. É o `minCentro` da D14.
  static const double minCenterWidth = 320;

  /// Largura mínima de um painel lateral (esquerdo/direito) do
  /// `ResizableSplitView` — piso abaixo do qual o painel deixa de encolher
  /// (default de `ResizableSplitView.minPanelWidth`, e um dos termos do
  /// piso mecânico do workspace, [workspaceMinimumWidth]).
  static const double workspacePanelMinWidth = 200;

  /// Largura máxima de um painel lateral do `ResizableSplitView` — teto do
  /// arraste e do reclamp na restauração da persistência de layout (D13).
  static const double workspacePanelMaxWidth = 480;

  /// Largura inicial do painel esquerdo do `ResizableSplitView`, antes de
  /// qualquer arraste ou layout restaurado (F6).
  static const double workspacePanelDefaultLeftWidth = 280;

  /// Largura inicial do painel direito do `ResizableSplitView` — mesmo papel
  /// de [workspacePanelDefaultLeftWidth], para o outro lado.
  static const double workspacePanelDefaultRightWidth = 320;

  /// Largura somada dos dois `ResizeHandle` (6px cada) entre os três
  /// painéis do `ResizableSplitView` — o "12" da D14.
  static const double workspaceDividersWidth = 12;

  /// Piso mecânico do workspace do editor (D14): abaixo desta largura, o
  /// `ResizableSplitView` deixa de encolher os painéis e passa a rolar na
  /// horizontal — nada desaparece, nada mente. Somatório dos mínimos:
  /// painel esquerdo + painel direito ([workspacePanelMinWidth] cada) + os
  /// dois `ResizeHandle` ([workspaceDividersWidth]) + [minCenterWidth].
  /// Derivado, não reescrito à mão — se um dos mínimos mudar (ex.: 5.3
  /// acrescenta um terceiro painel lateral), este valor muda junto, e é
  /// dele que os aceites de outras fases tiram a largura de teste (R13).
  static const double workspaceMinimumWidth =
      2 * workspacePanelMinWidth + workspaceDividersWidth + minCenterWidth;

  // F3 — piso do shell (D35).
  /// Altura fixa da faixa 1 do `AppShell` (wordmark + ações + status + tema).
  static const double topBarHeight = 56;

  /// Altura fixa da faixa 2 do `AppShell` (breadcrumb).
  static const double breadcrumbBarHeight = 30;

  /// Abaixo desta largura, a `AppShellTopBar` degrada em três peças (D35):
  /// wordmark curto, a ação `filled` primária vira só ícone (um toque) e as
  /// demais colapsam no `AppShellActionsOverflowMenu`. Não é breakpoint — é
  /// o limiar em que a parte rígida do shell (wordmark + desfazer + refazer
  /// + Salvar + Publicar + Despublicar + Histórico + botão de tema) para de
  /// caber (mesmo papel de `contentPanelWideHeaderFitWidth`). Só `Histórico`
  /// é `outlined` com rótulo (T1.1 do item 50); `Despublicar` continua
  /// `icon` — ação rara e destrutiva, não a que se procura. O indicador de
  /// status é `Flexible` e não entra nessa conta — ele encolhe com ellipsis
  /// em vez de forçar a largura. Medido com a fonte real do app
  /// (`test/support/app_fonts.dart`, não a de teste do Flutter, que infla o
  /// texto): o cruzamento ficou em ~794px nos três estados de publicação;
  /// os 46px de folga (mesma margem usada nas calibrações anteriores)
  /// cobrem variação de hinting entre ambientes — decisão do dono do
  /// produto em 2026-08-19, registrada em
  /// `docs/plans/50-historico-seguro/plan.md` (T1).
  static const double topBarActionsFitWidth = 840;

  /// Altura da barra de ferramentas do canvas (presets de device + zoom).
  static const double canvasToolbarHeight = 44;

  /// Abaixo desta largura **disponível para a barra do canvas** (não a da
  /// janela — o painel central encolhe sozinho quando os laterais abrem), o
  /// texto de dimensão do preset sai: ele é o único item redundante da barra,
  /// porque o tooltip de cada preset já diz `393×852`. Mesmo papel de
  /// [topBarActionsFitWidth].
  static const double canvasToolbarDimensionsFitWidth = 650;

  /// Abaixo desta largura, as ações secundárias da barra do canvas (ver no
  /// celular, tela cheia) colapsam no `AppShellActionsOverflowMenu`. Ficam
  /// sempre visíveis os presets de device, o ajuste à janela e o grupo de
  /// zoom — os controles sem os quais um canvas estreito não é utilizável.
  static const double canvasToolbarActionsFitWidth = 580;

  /// O piso da barra: abaixo desta largura sobram só os presets de device e
  /// os botões +/- de zoom, com o ajuste à janela indo para o menu, o
  /// percentual saindo (o mock já mostra a escala) e os respiros caindo para
  /// [AppSpacing.s8]. Existe porque o painel central encolhe até
  /// [minCenterWidth] antes de o workspace passar a rolar — e a barra tem de
  /// caber **lá**, não só em janela confortável.
  static const double canvasToolbarDenseFitWidth = 460;

  /// Vão entre o mock do rascunho e o mock da versão comparada, no modo de
  /// comparação. Desconta-se da largura antes de calcular a escala: a escala
  /// é **uma só** para os dois lados, porque mocks em tamanhos diferentes
  /// não se comparam a olho.
  static const double canvasCompareGutter = 24;

  /// Piso da escala abaixo do qual o modo de comparação deixa de mostrar os
  /// dois mocks lado a lado e passa a mostrar um por vez, com alternador.
  ///
  /// É o mesmo piso do zoom manual do editor (`EditorCubit.minZoom`): abaixo
  /// dele o próprio editor já considera o mock pequeno demais para trabalhar,
  /// e dois mocks nesse tamanho seriam duas ilegibilidades lado a lado. O
  /// critério é a **escala resultante**, não uma largura de janela fixa,
  /// porque a mesma janela comporta dois smartphones (393pt) e não comporta
  /// dois tablets (820pt).
  static const double canvasCompareMinSplitScale = 0.4;

  /// Abaixo desta largura **disponível para a barra da versão comparada**, os
  /// rótulos saem e sobram os ícones: na faixa estreita o mock já ocupa a
  /// largura inteira e a barra tem de caber junto dele.
  static const double versionCompareBarLabelsFitWidth = 520;

  // F3 — status bar do mock (D29).
  /// Largura da cápsula do indicador de home do mock — cabe sem colidir com
  /// as bordas no menor preset (Smartphone, 393 de largura).
  static const double deviceHomeIndicatorWidth = 120;

  /// Espessura da cápsula do indicador de home do mock.
  static const double deviceHomeIndicatorHeight = 4;
}
