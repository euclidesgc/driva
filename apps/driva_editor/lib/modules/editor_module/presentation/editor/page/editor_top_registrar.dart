import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

class EditorTopRegistrar extends StatelessWidget {
  const EditorTopRegistrar({
    required this.projectFuture,
    required this.child,
    super.key,
  });

  final Future<Either<Failure, Project>> projectFuture;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return FutureBuilder<Either<Failure, Project>>(
      future: projectFuture,
      builder: (context, snapshot) {
        final projectTitle = switch (snapshot.data) {
          Right(value: final project) => project.title,
          _ => 'Projeto',
        };
        return BlocSelector<EditorCubit, EditorState, (String, SaveStatus)>(
          selector: (state) => state is EditorReady
              ? (state.document.name, state.saveStatus)
              : ('', SaveStatus.saved),
          builder: (context, vm) {
            final (contentName, status) = vm;
            return AppShellSlot(
              crumbs: [
                const Crumb(
                  label: 'Projetos',
                  routeName: ProjectsRoutes.projectsName,
                ),
                Crumb(
                  label: projectTitle,
                  routeName: ContentsRoutes.projectDetailName,
                  pathParameters: {'id': cubit.projectId},
                ),
                Crumb(label: contentName),
              ],
              status: _statusFor(status),
              actions: [
                AppBarAction.filled(
                  label: 'Salvar',
                  icon: Icons.save_outlined,
                  onPressed: status == SaveStatus.saving ? null : cubit.save,
                ),
                const AppBarAction.outlined(
                  label: 'Publish',
                  tooltip: 'Publicação chega no incremento I4',
                ),
              ],
              child: child,
            );
          },
        );
      },
    );
  }
}

AppBarStatus _statusFor(SaveStatus status) => switch (status) {
  SaveStatus.saved => const AppBarStatus(
    icon: Icons.check_circle,
    label: 'Salvo',
    tone: AppBarStatusTone.success,
  ),
  SaveStatus.dirty => const AppBarStatus(
    icon: Icons.edit_outlined,
    label: 'Não salvo',
    tone: AppBarStatusTone.neutral,
  ),
  SaveStatus.saving => const AppBarStatus(
    icon: Icons.sync,
    label: 'Salvando…',
    tone: AppBarStatusTone.neutral,
  ),
  SaveStatus.saveFailed => const AppBarStatus(
    icon: Icons.error_outline,
    label: 'Falha ao salvar',
    tone: AppBarStatusTone.danger,
  ),
};
