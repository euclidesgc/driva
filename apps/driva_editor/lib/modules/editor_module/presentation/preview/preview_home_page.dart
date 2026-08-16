import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Destino do `start_url` do manifest do preview (D31, item 41): quem toca o
/// ícone da tela inicial cai aqui, sem `projectId`/`id` — precisa de um
/// caminho para fora, não pode terminar em beco.
class PreviewHomePage extends StatelessWidget {
  const PreviewHomePage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) =>
      const PreviewHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Preview do driva',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s12),
              const Text(
                'Isto é um preview de como o conteúdo aparece no app de '
                'verdade — abra um pelo editor para pré-visualizá-lo aqui.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s24),
              FilledButton(
                onPressed: () => context.goNamed(ProjectsRoutes.projectsName),
                child: const Text('Ver projetos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
