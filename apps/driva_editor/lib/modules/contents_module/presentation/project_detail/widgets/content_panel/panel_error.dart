import 'package:flutter/material.dart';

import '../../../../../../core/error/error.dart';
import '../../../../../../core/theme/app_spacing.dart';

class PanelError extends StatelessWidget {
  const PanelError({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
      NotFoundFailure() => 'Nada encontrado.',
      ConflictFailure(message: final m) => m,
      ValidationFailure(message: final m) => m,
      UnexpectedFailure() => 'Algo deu errado.',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.s12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
