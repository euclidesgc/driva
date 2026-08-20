import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_frame.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/preview_surface.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// O mock do rascunho — o que sempre esteve no canvas, editável e alvo de
/// arraste. Virou widget próprio quando o modo de comparação passou a pôr um
/// segundo mock ao lado: o `DragTarget` precisa terminar aqui dentro, para
/// que soltar um widget da paleta sobre a versão histórica não o adicione ao
/// rascunho.
class CanvasDraftMock extends StatelessWidget {
  const CanvasDraftMock({
    required this.device,
    required this.effectiveScale,
    required this.onSelect,
    required this.onDropOnDevice,
    required this.onDropOnNode,
    this.imageUrlResolver,
    super.key,
  });

  final DevicePreset device;
  final double effectiveScale;
  final ValueChanged<String?> onSelect;
  final ValueChanged<DragPayload> onDropOnDevice;
  final void Function(DragPayload payload, String targetId) onDropOnNode;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragPayload>(
      onAcceptWithDetails: (details) => onDropOnDevice(details.data),
      builder: (context, candidates, _) => InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(AppSpacing.s64),
        minScale: 1,
        maxScale: 1,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Transform.scale(
            scale: effectiveScale,
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: DeviceFrame(
                device: device,
                highlighted: candidates.isNotEmpty,
                child: PreviewSurface(
                  onSelect: onSelect,
                  onDropOn: onDropOnNode,
                  imageUrlResolver: imageUrlResolver,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
