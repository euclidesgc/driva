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
    this.imageUrlResolver,
    this.onOpenPreview,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(
          constraints.maxWidth - AppSpacing.s32 * 2,
          constraints.maxHeight -
              AppSizes.canvasToolbarHeight -
              AppSpacing.s32 * 2,
        );
        final effectiveScale = fitToWindow
            ? fitScaleFor(frame: device.frameSize, viewport: viewport)
            : zoom;
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
        );
      },
    );
  }
}
