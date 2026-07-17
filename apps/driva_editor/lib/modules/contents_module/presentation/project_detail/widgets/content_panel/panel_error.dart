import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PanelError extends StatelessWidget {
  const PanelError({required this.failure, required this.onRetry, super.key});

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
