import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../../../core/error/error.dart';
import '../../../../../core/theme/editor_colors.dart';
import '../../../../../core/widgets/layout/layout.dart';
import '../../../../projects_module/projects_module.dart';
import '../cubit/editor_cubit.dart';
import 'center_area.dart';
import 'editor_intents.dart';
import 'editor_top_registrar.dart';
import 'inspector_area.dart';
import 'left_panel.dart';

/// Casca do editor pronto. Construída UMA vez (a `buildWhen` acima só troca no
/// tipo do estado); os painéis internos assinam suas fatias via [BlocSelector].
class EditorWorkspace extends StatelessWidget {
  const EditorWorkspace({super.key, required this.projectFuture});

  final Future<Either<Failure, Project>> projectFuture;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final colors = Theme.of(context).extension<EditorColors>()!;

    // Corpo pesado construído UMA vez; o registrador do topo (que reconstrói ao
    // mudar o status de salvamento) o repassa por identidade, sem rebuildá-lo.
    final workspace = Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.delete): const DeleteIntent(),
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
