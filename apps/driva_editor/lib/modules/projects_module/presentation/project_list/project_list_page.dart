import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/theme/editor_colors.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../../../injection.dart';
import '../../../contents_module/contents_module.dart';
import '../../../preferences_module/preferences_module.dart';
import '../../domain/entities/entities.dart';
import '../../domain/use_cases/use_cases.dart';
import '../../projects_routes.dart';
import '../widgets/project_card.dart';
import 'cubit/project_list_cubit.dart';
import 'widgets/project_form_dialog.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => ProjectListCubit(
        getProjects: getIt<GetProjectsUseCase>(),
        createProject: getIt<CreateProjectUseCase>(),
        updateProject: getIt<UpdateProjectUseCase>(),
        archiveProject: getIt<ArchiveProjectUseCase>(),
      )..load(),
      child: const ProjectListPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppWordmark(),
        actions: [
          BlocBuilder<ProjectListCubit, ProjectListState>(
            builder: (context, state) {
              final archivedCount = switch (state) {
                ProjectListLoaded(:final archivedCount) => archivedCount,
                ProjectListEmpty(:final archivedCount) => archivedCount,
                _ => 0,
              };
              return _ArchivedLinkButton(count: archivedCount);
            },
          ),
          const SizedBox(width: 4),
          const ThemeModeButton(),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _openCreateForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo projeto'),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProjectListCubit, ProjectListState>(
        builder: (context, state) {
          return switch (state) {
            ProjectListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProjectListEmpty() => _EmptyProjects(
              onCreate: () => _openCreateForm(context),
            ),
            final ProjectListError s => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_messageFor(s.failure)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<ProjectListCubit>().load(),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
            final ProjectListLoaded s => _ProjectsHome(projects: s.projects),
          };
        },
      ),
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

  static Future<void> _openEditForm(
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

/// Link do header para a área de Arquivados; mostra a contagem quando > 0.
class _ArchivedLinkButton extends StatelessWidget {
  const _ArchivedLinkButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 0 ? 'Arquivados ($count)' : 'Arquivados';
    return Tooltip(
      message: 'Ver projetos arquivados',
      child: Semantics(
        button: true,
        label: label,
        child: TextButton.icon(
          onPressed: () => context.goNamed(ProjectsRoutes.archivedName),
          icon: const Icon(Icons.archive_outlined, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}

class _ProjectsHome extends StatelessWidget {
  const _ProjectsHome({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 80),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Projetos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${projects.length} ${projects.length == 1 ? 'projeto' : 'projetos'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                mainAxisExtent: 290,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => context.goNamed(
                    ContentsRoutes.projectDetailName,
                    pathParameters: {'id': project.id},
                  ),
                  onEdit: () => ProjectListPage._openEditForm(context, project),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primaryTint,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.layers_outlined,
                  size: 28,
                  color: Color(0xFFE8602C),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum projeto ainda',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Crie seu primeiro projeto para organizar categorias e '
                'conteúdos do app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.inkSecondary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Novo projeto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
