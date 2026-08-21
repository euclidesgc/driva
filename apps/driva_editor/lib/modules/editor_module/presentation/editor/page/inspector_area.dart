import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_compare_section.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_vm.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InspectorArea extends StatelessWidget {
  const InspectorArea({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final collapsedSections = EditorLayoutScope.of(
      context,
    )?.collapsedInspectorSections;
    return BlocSelector<EditorCubit, EditorState, InspectorVm?>(
      selector: (state) {
        if (state is! EditorReady) return null;
        final selectedNode = state.selectedNode;
        return InspectorVm(
          node: selectedNode,
          isRoot:
              selectedNode != null &&
              selectedNode.id == state.document.root?.id,
          safeArea: state.document.safeArea,
          contentName: state.document.name,
          contentSlug: state.document.slug,
          isReadOnly: state.isReadOnly,
        );
      },
      builder: (context, vm) => vm == null
          ? const SizedBox.shrink()
          : InspectorPanel(
              compareSection: InspectorCompareSection(nodeId: vm.node?.id),
              node: vm.node,
              isRoot: vm.isRoot,
              safeArea: vm.safeArea,
              contentName: vm.contentName,
              contentSlug: vm.contentSlug,
              onUpdateProps: cubit.updateProps,
              onUpdateSafeAreaProps: cubit.updateSafeAreaProps,
              onRemove: cubit.removeNode,
              onWrap: cubit.wrapSelected,
              collapsedSections: collapsedSections,
              isReadOnly: vm.isReadOnly,
            ),
    );
  }
}
