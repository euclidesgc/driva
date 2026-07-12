import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/theme/editor_colors.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../../../injection.dart';
import '../../domain/entities/entities.dart';
import '../../domain/use_cases/use_cases.dart';
import '../../projects_routes.dart';
import 'cubit/archived_projects_cubit.dart';

class ArchivedProjectsPage extends StatelessWidget {
  const ArchivedProjectsPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => ArchivedProjectsCubit(
        getProjects: getIt<GetProjectsUseCase>(),
        unarchiveProject: getIt<UnarchiveProjectUseCase>(),
        deleteProject: getIt<DeleteProjectUseCase>(),
      )..load(),
      child: const ArchivedProjectsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        leading: Tooltip(
          message: 'Voltar para projetos',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed(ProjectsRoutes.projectsName),
          ),
        ),
        title: const AppWordmark(),
      ),
      body: BlocBuilder<ArchivedProjectsCubit, ArchivedProjectsState>(
        builder: (context, state) {
          return switch (state) {
            ArchivedProjectsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ArchivedProjectsEmpty() => const _EmptyArchived(),
            final ArchivedProjectsError s => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_messageFor(s.failure)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<ArchivedProjectsCubit>().load(),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
            final ArchivedProjectsLoaded s => _ArchivedProjectsList(
              projects: s.projects,
            ),
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
}

class _ArchivedProjectsList extends StatelessWidget {
  const _ArchivedProjectsList({required this.projects});

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
                  'Arquivados',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${projects.length} '
                  '${projects.length == 1 ? 'projeto' : 'projetos'}',
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
                mainAxisExtent: 312,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) =>
                  _ArchivedProjectCard(project: projects[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedProjectCard extends StatelessWidget {
  const _ArchivedProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;

    return Opacity(
      // Visual atenuado (não é o único sinal — o badge textual abaixo
      // marca "Arquivado" independente de cor/opacidade).
      opacity: 0.72,
      child: Container(
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: colors.panelAlt),
                  if (project.imageUrl != null && project.imageUrl!.isNotEmpty)
                    Image.network(
                      project.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Semantics(
                      label: 'Projeto arquivado',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.archive_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Arquivado',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 38,
                    child: Text(
                      project.description?.isNotEmpty == true
                          ? project.description!
                          : 'Sem descrição.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.inkSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: 'Restaurar projeto para a lista ativa',
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmRestore(context, project),
                            icon: const Icon(
                              Icons.unarchive_outlined,
                              size: 16,
                            ),
                            label: const Text('Restaurar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Excluir definitivamente',
                        child: Semantics(
                          button: true,
                          label:
                              'Excluir projeto ${project.title} '
                              'definitivamente',
                          child: IconButton(
                            onPressed: () =>
                                _confirmDeleteForever(context, project),
                            icon: Icon(
                              Icons.delete_forever_outlined,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, Project project) async {
    final cubit = context.read<ArchivedProjectsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar projeto?'),
        content: Text(
          '"${project.title}" volta a aparecer na lista de projetos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await cubit.restore(project.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ArchivedProjectsPage._messageFor(failure))),
      ),
      (_) {},
    );
  }

  /// Confirmação DUPLA: primeiro diálogo explica a consequência (cascade
  /// total, sem volta); o segundo exige digitar o título do projeto para
  /// confirmar — barra exclusão acidental por duplo clique/engano.
  Future<void> _confirmDeleteForever(
    BuildContext context,
    Project project,
  ) async {
    final cubit = context.read<ArchivedProjectsCubit>();

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir projeto definitivamente?'),
        content: Text(
          'Isto apaga o projeto "${project.title}" e todo o seu conteúdo '
          '(categorias e conteúdos), sem volta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (firstConfirm != true || !context.mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _TypeToConfirmDialog(projectTitle: project.title),
    );
    if (secondConfirm != true || !context.mounted) return;

    final result = await cubit.deleteForever(project.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ArchivedProjectsPage._messageFor(failure))),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${project.title}" foi excluído definitivamente.'),
        ),
      ),
    );
  }
}

/// Segunda etapa da confirmação dupla: exige digitar o título do projeto
/// para habilitar o botão de excluir — a barreira extra contra exclusão
/// definitiva por engano (ação irreversível, cascade total).
class _TypeToConfirmDialog extends StatefulWidget {
  const _TypeToConfirmDialog({required this.projectTitle});

  final String projectTitle;

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Confirmação final'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            label:
                'Aviso: esta ação não tem volta. Digite o nome do projeto '
                'para confirmar.',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Esta ação não tem volta. Digite o nome do projeto '
                    'para confirmar a exclusão definitiva.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Digite "${widget.projectTitle}" para confirmar:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nome do projeto'),
            onChanged: (value) =>
                setState(() => _matches = value.trim() == widget.projectTitle),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Excluir definitivamente'),
        ),
      ],
    );
  }
}

class _EmptyArchived extends StatelessWidget {
  const _EmptyArchived();

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
                  Icons.archive_outlined,
                  size: 28,
                  color: Color(0xFFE8602C),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum projeto arquivado',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Projetos arquivados aparecem aqui. Você pode restaurá-los '
                'ou excluí-los definitivamente a qualquer momento.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
