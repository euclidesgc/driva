import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/project_list_page.dart';
import 'package:driva_editor/modules/projects_module/presentation/widgets/project_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProjectsHome extends StatelessWidget {
  const ProjectsHome({required this.projects, super.key});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s28,
        AppSpacing.s34,
        AppSpacing.s28,
        AppSpacing.s80,
      ),
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
                const SizedBox(width: AppSpacing.s12),
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
                mainAxisSpacing: AppSpacing.s20,
                crossAxisSpacing: AppSpacing.s20,
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
                  onEdit: () => ProjectListPage.openEditForm(context, project),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
