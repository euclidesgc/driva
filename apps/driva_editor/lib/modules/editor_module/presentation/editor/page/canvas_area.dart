import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/editor_cubit.dart';
import '../device_preset.dart';
import '../widgets/canvas_panel.dart';

/// Canvas central: reage só a `device`/`zoom` (o preview do documento é
/// assinado e throttled dentro do próprio [CanvasPanel]).
class CanvasArea extends StatelessWidget {
  const CanvasArea({super.key});

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
        onAddToRoot: (type) {
          final state = cubit.state;
          if (state is! EditorReady) return;
          final root = state.document.root;
          // Conteúdo vazio: o nó vira a raiz (parentId null resolve isso).
          cubit.addNode(type, parentId: root?.id);
        },
      ),
    );
  }
}
