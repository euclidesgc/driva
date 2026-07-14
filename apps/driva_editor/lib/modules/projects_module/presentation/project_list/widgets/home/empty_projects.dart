import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radii.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_theme.dart';
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
          padding: const EdgeInsets.symmetric(
            vertical: 90,
            horizontal: AppSpacing.s20,
          ),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(AppRadii.r16),
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
                  borderRadius: BorderRadius.circular(AppRadii.r15),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.layers_outlined,
                  size: 28,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Nenhum projeto ainda',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(
                'Crie seu primeiro projeto para organizar categorias e '
                'conteúdos do app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
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
