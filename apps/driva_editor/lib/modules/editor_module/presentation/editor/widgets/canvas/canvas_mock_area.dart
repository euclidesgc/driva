import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_draft_mock.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// A área dos mocks abaixo da `CanvasToolbar`: só o rascunho no modo normal,
/// rascunho e versão lado a lado no modo de comparação.
///
/// [comparePane] entra como **irmão** de [CanvasDraftMock], nunca como filho:
/// o `DragTarget` do rascunho termina dentro do `CanvasDraftMock`, então
/// soltar um widget da paleta sobre a versão histórica não pode alterar o
/// rascunho.
class CanvasMockArea extends StatelessWidget {
  const CanvasMockArea({
    required this.device,
    required this.effectiveScale,
    required this.onSelect,
    required this.onDropOnDevice,
    required this.onDropOnNode,
    this.comparePane,
    this.imageUrlResolver,
    super.key,
  });

  final DevicePreset device;
  final double effectiveScale;
  final ValueChanged<String?> onSelect;
  final ValueChanged<DragPayload> onDropOnDevice;
  final void Function(DragPayload payload, String targetId) onDropOnNode;
  final Widget? comparePane;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final draft = CanvasDraftMock(
      device: device,
      effectiveScale: effectiveScale,
      onSelect: onSelect,
      onDropOnDevice: onDropOnDevice,
      onDropOnNode: onDropOnNode,
      imageUrlResolver: imageUrlResolver,
    );
    final pane = comparePane;
    if (pane == null) return draft;
    return Row(
      children: [
        Expanded(child: draft),
        const SizedBox(width: AppSizes.canvasCompareGutter),
        Expanded(child: pane),
      ],
    );
  }
}
