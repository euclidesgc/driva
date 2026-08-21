import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

class CanvasPanelBody extends StatelessWidget {
  const CanvasPanelBody({
    required this.device,
    required this.effectiveScale,
    required this.fitToWindow,
    required this.onSelect,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onToggleFitToWindow,
    required this.onDropOnDevice,
    required this.onDropOnNode,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.comparePane,
    this.compareModeBar,
    this.imageUrlResolver,
    this.onOpenPreview,
    this.isComparing = false,
    this.onReturnToPublished,
    super.key,
  });

  final DevicePreset device;

  /// Escala de fato aplicada ao `Transform.scale` — o resultado de
  /// [fitScaleFor] quando [fitToWindow] está ligado, ou o `zoom` manual do
  /// cubit quando não (calculado por quem monta este widget).
  final double effectiveScale;
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

  /// O mock da versão comparada, quando o modo de comparação está ativo.
  /// Entra como irmão de [CanvasDraftMock] numa `Row`, e não como filho
  /// dele: o `DragTarget` do rascunho termina lá dentro, então soltar um
  /// widget da paleta sobre a versão histórica não altera o rascunho.
  final Widget? comparePane;

  /// A barra única do modo de comparação lado a lado, acima da `Row` dos
  /// dois mocks — `null` fora do modo ou na faixa estreita de um mock por
  /// vez, onde `CanvasCompareSideToggle` já identifica os lados.
  final Widget? compareModeBar;

  final bool isComparing;
  final VoidCallback? onReturnToPublished;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CanvasToolbar(
          device: device,
          effectiveScale: effectiveScale,
          fitToWindow: fitToWindow,
          onChangeDevice: onChangeDevice,
          onChangeZoom: onChangeZoom,
          onToggleFitToWindow: onToggleFitToWindow,
          onOpenPreview: onOpenPreview,
          isFullscreen: isFullscreen,
          onToggleFullscreen: onToggleFullscreen,
          isComparing: isComparing,
          onReturnToPublished: onReturnToPublished,
        ),
        if (compareModeBar case final bar?)
          SizedBox(width: double.infinity, child: bar),
        Expanded(
          child: CanvasMockArea(
            device: device,
            effectiveScale: effectiveScale,
            onSelect: onSelect,
            onDropOnDevice: onDropOnDevice,
            onDropOnNode: onDropOnNode,
            comparePane: comparePane,
            imageUrlResolver: imageUrlResolver,
          ),
        ),
      ],
    );
  }
}
