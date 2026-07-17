import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class TreeErrorView extends StatelessWidget {
  const TreeErrorView({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final Object failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar as categorias.'),
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
