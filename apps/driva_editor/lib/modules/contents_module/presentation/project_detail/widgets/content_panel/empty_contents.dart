import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radii.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/editor_colors.dart';

class EmptyContents extends StatelessWidget {
  const EmptyContents({
    super.key,
    required this.categoryLabel,
    this.isAllContents = false,
    required this.onCreate,
  });

  final String categoryLabel;
  final bool isAllContents;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 70,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadii.r14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.s14),
              Text(
                isAllContents
                    ? 'Nenhum conteúdo neste projeto ainda'
                    : 'Nenhum conteúdo em "$categoryLabel"',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.s5),
              Text(
                isAllContents
                    ? 'Crie o primeiro conteúdo do projeto.'
                    : 'Crie o primeiro conteúdo desta categoria.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Novo conteúdo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
