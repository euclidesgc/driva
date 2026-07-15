import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../projects_module/projects_module.dart';

class InvalidProjectScreen extends StatelessWidget {
  const InvalidProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Link de projeto inválido.'),
            const SizedBox(height: AppSpacing.s12),
            OutlinedButton(
              onPressed: () => context.goNamed(ProjectsRoutes.projectsName),
              child: const Text('Voltar aos projetos'),
            ),
          ],
        ),
      ),
    );
  }
}
