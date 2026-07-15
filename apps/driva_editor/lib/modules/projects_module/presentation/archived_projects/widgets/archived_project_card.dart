import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../widgets/project_card.dart';
import '../archived_projects_page.dart';
import '../cubit/archived_projects_cubit.dart';
import 'type_to_confirm_dialog.dart';

class ArchivedProjectCard extends StatelessWidget {
  const ArchivedProjectCard({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ProjectCard(
      project: project,
      attenuated: true,
      coverOverlay: Positioned(
        left: 12,
        top: 12,
        child: Semantics(
          label: 'Projeto arquivado',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      actions: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: 'Restaurar projeto para a lista ativa',
              child: OutlinedButton.icon(
                onPressed: () => _confirmRestore(context, project),
                icon: const Icon(Icons.unarchive_outlined, size: 16),
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
                onPressed: () => _confirmDeleteForever(context, project),
                icon: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
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
        SnackBar(content: Text(ArchivedProjectsPage.messageFor(failure))),
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
          TypeToConfirmDialog(projectTitle: project.title),
    );
    if (secondConfirm != true || !context.mounted) return;

    final result = await cubit.deleteForever(project.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ArchivedProjectsPage.messageFor(failure))),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${project.title}" foi excluído definitivamente.'),
        ),
      ),
    );
  }
}
