import 'dart:async';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/projects_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/projects_module/presentation/archived_projects/cubit/archived_projects_cubit.dart';
import 'package:driva_editor/modules/projects_module/presentation/archived_projects/widgets/widgets.dart';
import 'package:driva_editor/modules/projects_module/projects_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ArchivedProjectsPage extends StatelessWidget {
  const ArchivedProjectsPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) {
        final cubit = ArchivedProjectsCubit(
          getProjects: getIt<GetProjectsUseCase>(),
          unarchiveProject: getIt<UnarchiveProjectUseCase>(),
          deleteProject: getIt<DeleteProjectUseCase>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const ArchivedProjectsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShellSlot(
      crumbs: const [
        Crumb(label: 'Projetos', routeName: ProjectsRoutes.projectsName),
        Crumb(label: 'Arquivados'),
      ],
      child: Scaffold(
        body: BlocBuilder<ArchivedProjectsCubit, ArchivedProjectsState>(
          builder: (context, state) {
            return switch (state) {
              ArchivedProjectsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ArchivedProjectsEmpty() => const EmptyArchived(),
              final ArchivedProjectsError s => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(messageFor(s.failure)),
                    const SizedBox(height: AppSpacing.s12),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<ArchivedProjectsCubit>().load(),
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
              final ArchivedProjectsLoaded s => ArchivedProjectsList(
                projects: s.projects,
              ),
            };
          },
        ),
      ),
    );
  }

  static String messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Nada encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado.',
  };
}
