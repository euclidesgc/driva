import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/layout/layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/center_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_intents.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_top_registrar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

class EditorWorkspace extends StatelessWidget {
  const EditorWorkspace({required this.projectFuture, super.key});

  final Future<Either<Failure, Project>> projectFuture;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final colors = Theme.of(context).extension<EditorColors>()!;

    final workspace = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent(),
        SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => cubit.save()),
          DeleteIntent: CallbackAction<DeleteIntent>(
            onInvoke: (_) => cubit.removeSelected(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: ResizableSplitView(
              left: const LeftPanel(),
              center: const CenterArea(),
              right: ColoredBox(
                color: colors.panel,
                child: const InspectorArea(),
              ),
            ),
          ),
        ),
      ),
    );

    return EditorTopRegistrar(projectFuture: projectFuture, child: workspace);
  }
}
