import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_vm.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InspectorArea extends StatelessWidget {
  const InspectorArea({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocSelector<EditorCubit, EditorState, InspectorVm?>(
      selector: (state) {
        if (state is! EditorReady) return null;
        final root = state.document.root;
        final node = state.selectedNode ?? root;
        final isContent = state.selectedNode == null;
        return InspectorVm(
          node: node,
          isContent: isContent,
          contentName: state.document.name,
          contentSlug: state.document.slug,
        );
      },
      builder: (context, vm) => vm == null
          ? const SizedBox.shrink()
          : InspectorPanel(
              node: vm.node,
              isContent: vm.isContent,
              contentName: vm.contentName,
              contentSlug: vm.contentSlug,
              onUpdateProps: cubit.updateProps,
              onRemove: cubit.removeNode,
            ),
    );
  }
}
