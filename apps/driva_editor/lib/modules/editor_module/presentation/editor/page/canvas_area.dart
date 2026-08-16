import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

class CanvasArea extends StatelessWidget {
  const CanvasArea({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocSelector<
      EditorCubit,
      EditorState,
      ({DevicePreset device, double zoom})
    >(
      selector: (state) => state is EditorReady
          ? (device: state.device, zoom: state.zoom)
          : (device: DevicePreset.smartphone, zoom: 0.9),
      builder: (context, vm) => CanvasPanel(
        device: vm.device,
        zoom: vm.zoom,
        onSelect: cubit.selectNode,
        onChangeDevice: cubit.changeDevice,
        onChangeZoom: cubit.changeZoom,
        imageUrlResolver: imageUrlResolver,
        onDropOnDevice: (payload) {
          final state = cubit.state;
          if (state is! EditorReady) return;
          // Conteúdo vazio: o nó vira a raiz (alvo null resolve isso).
          _dispatch(cubit, payload, state.document.root?.id);
        },
        onDropOnNode: (payload, targetId) =>
            _dispatch(cubit, payload, targetId),
      ),
    );
  }

  void _dispatch(EditorCubit cubit, DragPayload payload, String? targetId) {
    switch (payload) {
      case PaletteDragPayload(:final type):
        cubit.addNode(type, targetId: targetId);
      case NodeDragPayload(:final nodeId) when targetId != null:
        cubit.moveNode(nodeId, targetId);
      case NodeDragPayload():
        break;
    }
  }
}
