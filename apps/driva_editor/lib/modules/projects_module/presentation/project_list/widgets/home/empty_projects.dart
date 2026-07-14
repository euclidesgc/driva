import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';

class EmptyProjects extends StatelessWidget {
  const EmptyProjects({super.key, required this.onCreate});

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
