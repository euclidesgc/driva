import 'dart:async';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/cubit/project_list_cubit.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/home/home.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/project_form_dialog.dart';
import 'package:driva_editor/modules/projects_module/projects_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) {
        final cubit = ProjectListCubit(
          getProjects: getIt<GetProjectsUseCase>(),
          createProject: getIt<CreateProjectUseCase>(),
          updateProject: getIt<UpdateProjectUseCase>(),
          archiveProject: getIt<ArchiveProjectUseCase>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const ProjectListPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProjectListCubit, ProjectListState, int>(
      selector: (state) => switch (state) {
        ProjectListLoaded(:final archivedCount) => archivedCount,
        ProjectListEmpty(:final archivedCount) => archivedCount,
        _ => 0,
      },
      builder: (context, archivedCount) {
        return AppShellSlot(
          crumbs: const [Crumb(label: 'Projetos')],
          actions: [
            AppBarAction.text(
              label: archivedCount > 0
                  ? 'Arquivados ($archivedCount)'
                  : 'Arquivados',
              icon: Icons.archive_outlined,
              tooltip: 'Ver projetos arquivados',
              onPressed: () => context.goNamed(ProjectsRoutes.archivedName),
            ),
            AppBarAction.filled(
              label: 'Novo projeto',
              icon: Icons.add,
              onPressed: () => _openCreateForm(context),
            ),
          ],
          child: Scaffold(
            body: BlocBuilder<ProjectListCubit, ProjectListState>(
              builder: (context, state) {
                return switch (state) {
                  ProjectListLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  ProjectListEmpty() => EmptyProjects(
                    onCreate: () => _openCreateForm(context),
                  ),
                  final ProjectListError s => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_messageFor(s.failure)),
                        const SizedBox(height: AppSpacing.s12),
                        OutlinedButton(
                          onPressed: () =>
                              context.read<ProjectListCubit>().load(),
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  ),
                  final ProjectListLoaded s => ProjectsHome(
                    projects: s.projects,
                  ),
                };
              },
            ),
          ),
        );
      },
    );
  }

  static String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Nada encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado.',
  };

  static Future<void> _openCreateForm(BuildContext context) async {
    final cubit = context.read<ProjectListCubit>();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ProjectFormDialog(
        title: 'Novo projeto',
        onSubmit: (form) => cubit.create(
          title: form.title,
          description: form.description,
          image: form.image,
        ),
      ),
    );
    if (result != true || !context.mounted) return;
  }

  static Future<void> openEditForm(
    BuildContext context,
    Project project,
  ) async {
    final cubit = context.read<ProjectListCubit>();
    await showDialog<bool>(
      context: context,
      builder: (_) => ProjectFormDialog(
        title: 'Editar projeto',
        initialTitle: project.title,
        initialDescription: project.description,
        initialImageUrl: project.imageUrl,
        onSubmit: (form) => cubit.update(
          project.id,
          title: form.title,
          description: form.description,
          image: form.image,
          removeImage: form.removeImage,
        ),
        onArchive: () => cubit.archive(project.id),
      ),
    );
  }
}
