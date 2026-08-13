import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/status_bar_vm.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatusBarArea extends StatelessWidget {
  const StatusBarArea({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocSelector<EditorCubit, EditorState, StatusBarVm?>(
      selector: (state) => state is EditorReady
          ? StatusBarVm(diagnostics: state.diagnostics, notice: state.notice)
          : null,
      builder: (context, vm) => vm == null
          ? const SizedBox.shrink()
          : EditorStatusBar(
              diagnostics: vm.diagnostics,
              notice: vm.notice,
              onSelectNode: cubit.selectNode,
            ),
    );
  }
}
