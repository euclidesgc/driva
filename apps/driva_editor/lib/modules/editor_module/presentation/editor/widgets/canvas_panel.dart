import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../device_preset.dart';
import 'canvas/canvas.dart';
import 'drag_payload.dart';

/// Canvas central: toolbar (dispositivo + zoom) e a moldura de celular
/// renderizando o documento com o renderer REAL (`SduiView`) — preview fiel
/// por construção. O `nodeWrapper` injeta seleção por clique e contorno.
///
/// Recebe só `device`/`zoom`; o preview do documento é assinado e **throttled**
/// dentro de [PreviewSurface], para digitação rápida não re-executar o
/// renderer a cada tecla.
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    super.key,
    required this.device,
    required this.zoom,
    required this.onSelect,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onAddToRoot,
  });

  final DevicePreset device;
  final double zoom;
  final ValueChanged<String?> onSelect;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;
  final ValueChanged<String> onAddToRoot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CanvasToolbar(
          device: device,
          zoom: zoom,
          onChangeDevice: onChangeDevice,
          onChangeZoom: onChangeZoom,
        ),
        Expanded(
          child: DragTarget<DragPayload>(
            // Soltar no canvas (fora da árvore) = adicionar ao fim do conteúdo.
            onAcceptWithDetails: (details) {
              if (details.data case PaletteDragPayload(:final type)) {
                onAddToRoot(type);
              }
            },
            builder: (context, candidates, _) => InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(AppSpacing.s64),
              minScale: 1,
              maxScale: 1,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s32),
                child: Transform.scale(
                  scale: zoom,
                  alignment: Alignment.topCenter,
                  // Isola a pintura do preview do resto do editor.
                  child: RepaintBoundary(
                    child: DeviceFrame(
                      device: device,
                      highlighted: candidates.isNotEmpty,
                      child: PreviewSurface(onSelect: onSelect),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
