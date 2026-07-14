import 'package:flutter/material.dart';

import '../../../domain/entities/entities.dart';
import 'archived_project_card.dart';

class ArchivedProjectsList extends StatelessWidget {
  const ArchivedProjectsList({super.key, required this.projects});

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
                mainAxisExtent: 336,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) =>
                  ArchivedProjectCard(project: projects[index]),
            ),
          ],
        ),
      ),
    );
  }
}
