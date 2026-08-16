import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PreviewErrorView extends StatelessWidget {
  const PreviewErrorView({required this.failure, super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Text(
          _messageFor(failure),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Conteúdo não encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => 'Spec inválido: $m',
    UnexpectedFailure() => 'Algo deu errado ao abrir o preview.',
  };
}
