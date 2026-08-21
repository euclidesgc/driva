import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Canvas central: toolbar (dispositivo + zoom) e a moldura de celular
/// renderizando o documento com o renderer REAL (`SduiView`) — preview fiel
/// por construção. O `nodeWrapper` injeta seleção por clique, contorno e o
/// arraste que reorganiza a árvore direto no mock.
///
/// Recebe só `device`/`zoom`/`fitToWindow`; o preview do documento é assinado
/// e **throttled** dentro de [PreviewSurface], para digitação rápida não
/// re-executar o renderer a cada tecla.
///
/// O [LayoutBuilder] mede o espaço inteiro do painel — toolbar incluída
/// (D9) — porque a barra precisa mostrar a mesma escala efetiva aplicada
/// ao `Transform.scale`. Fica fora do `InteractiveViewer` (`constrained:
/// false` adiante devolveria restrição infinita a um `LayoutBuilder` ali
/// dentro).
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    required this.device,
    required this.zoom,
    required this.fitToWindow,
    required this.onSelect,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onToggleFitToWindow,
    required this.onDropOnDevice,
    required this.onDropOnNode,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.compareBuilder,
    this.compareModeBar,
    this.onCompareSideChanged,
    this.compareSide = CanvasCompareSide.draft,
    this.imageUrlResolver,
    this.onOpenPreview,
    this.onReturnToPublished,
    super.key,
  });

  final DevicePreset device;
  final double zoom;
  final bool fitToWindow;
  final ValueChanged<String?> onSelect;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;
  final VoidCallback onToggleFitToWindow;

  final VoidCallback? onOpenPreview;

  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  /// Soltar fora de qualquer nó mira o conteúdo inteiro (raiz).
  final ValueChanged<DragPayload> onDropOnDevice;

  final void Function(DragPayload payload, String targetId) onDropOnNode;

  final SduiImageUrlResolver? imageUrlResolver;

  /// Monta o mock da versão comparada com a escala que este widget calculou.
  /// É builder e não widget pronto porque a escala é **uma só** para os dois
  /// lados — mocks em tamanhos diferentes não se comparam a olho — e ela só
  /// existe depois de medir o viewport aqui dentro.
  ///
  /// `sideBySide` diz se o resultado vai para a `Row` dos dois mocks (lado a
  /// lado, sem barra própria — a identificação vem de [compareModeBar]) ou
  /// para `CanvasCompareSingleMock` (um mock por vez, com a própria barra,
  /// já que ali não há segundo mock para alinhar).
  final Widget Function(double effectiveScale, {required bool sideBySide})?
  compareBuilder;

  /// A barra única do modo de comparação lado a lado (rascunho identificado
  /// à esquerda, candidata à direita) — some na faixa estreita de um mock
  /// por vez, onde `CanvasCompareSideToggle` já cumpre esse papel.
  final Widget? compareModeBar;

  /// D6: a volta à versão publicada, oferecida na barra do canvas só
  /// durante o modo — `null` também quando não há versão publicada.
  final VoidCallback? onReturnToPublished;

  /// Qual mock está visível quando a janela não comporta os dois.
  final CanvasCompareSide compareSide;
  final ValueChanged<CanvasCompareSide>? onCompareSideChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isComparing = compareBuilder != null;
        final splitWidth = isComparing
            ? (constraints.maxWidth - AppSizes.canvasCompareGutter) / 2
            : constraints.maxWidth;
        final baseHeight =
            constraints.maxHeight -
            AppSizes.canvasToolbarHeight -
            AppSpacing.s32 * 2;

        // A barra única do modo lado a lado soma a própria altura à do
        // `CanvasToolbar` — sem descontar as duas aqui, a escala calculada
        // ignoraria o espaço que ela ocupa e a moldura vazaria por baixo
        // dela (ou seria forçada a um tamanho menor que `effectiveScale`
        // promete, quebrando a paridade de altura com o rascunho).
        final compareModeBarHeight = isComparing && compareModeBar != null
            ? AppSizes.canvasToolbarHeight
            : 0.0;
        final splitViewport = Size(
          splitWidth - AppSpacing.s32 * 2,
          baseHeight - compareModeBarHeight,
        );
        final splitScale = fitScaleFor(
          frame: device.frameSize,
          viewport: splitViewport,
        );

        // Dois mocks só valem a pena enquanto cada um continua legível: abaixo
        // do piso, mostrar os dois seria mostrar duas ilegibilidades lado a
        // lado, e a escala volta a ser calculada sobre a largura inteira.
        final fitsSideBySide =
            isComparing && splitScale >= AppSizes.canvasCompareMinSplitScale;

        final fullViewport = Size(
          constraints.maxWidth - AppSpacing.s32 * 2,
          baseHeight,
        );
        final fullScale = fitScaleFor(
          frame: device.frameSize,
          viewport: fullViewport,
        );
        final effectiveScale = fitToWindow
            ? (fitsSideBySide ? splitScale : fullScale)
            : zoom;

        if (isComparing && !fitsSideBySide) {
          return CanvasCompareSingleMock(
            side: compareSide,
            onSideChanged: onCompareSideChanged ?? (_) {},
            comparePane: compareBuilder!(effectiveScale, sideBySide: false),
            draftPanel: CanvasPanelBody(
              device: device,
              effectiveScale: effectiveScale,
              fitToWindow: fitToWindow,
              onSelect: onSelect,
              onChangeDevice: onChangeDevice,
              onChangeZoom: onChangeZoom,
              onToggleFitToWindow: onToggleFitToWindow,
              onDropOnDevice: onDropOnDevice,
              onDropOnNode: onDropOnNode,
              imageUrlResolver: imageUrlResolver,
              onOpenPreview: onOpenPreview,
              isFullscreen: isFullscreen,
              onToggleFullscreen: onToggleFullscreen,
              isComparing: true,
              onReturnToPublished: onReturnToPublished,
            ),
          );
        }

        return CanvasPanelBody(
          device: device,
          effectiveScale: effectiveScale,
          fitToWindow: fitToWindow,
          onSelect: onSelect,
          onChangeDevice: onChangeDevice,
          onChangeZoom: onChangeZoom,
          onToggleFitToWindow: onToggleFitToWindow,
          onDropOnDevice: onDropOnDevice,
          onDropOnNode: onDropOnNode,
          imageUrlResolver: imageUrlResolver,
          onOpenPreview: onOpenPreview,
          isFullscreen: isFullscreen,
          onToggleFullscreen: onToggleFullscreen,
          comparePane: compareBuilder?.call(effectiveScale, sideBySide: true),
          compareModeBar: isComparing ? compareModeBar : null,
          isComparing: isComparing,
          onReturnToPublished: isComparing ? onReturnToPublished : null,
        );
      },
    );
  }
}
