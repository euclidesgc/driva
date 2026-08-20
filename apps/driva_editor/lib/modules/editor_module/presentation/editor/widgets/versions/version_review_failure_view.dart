import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_failure_message.dart';
import 'package:flutter/material.dart';

/// Falha ao buscar o detalhe da versão (T3, item 50): mensagem por tipo de
/// [Failure] e retry local — o histórico e o canvas continuam abertos atrás
/// deste diálogo, nunca fecham sozinhos por causa de um erro de leitura.
class VersionReviewFailureView extends StatelessWidget {
  const VersionReviewFailureView({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = versionFailureMessage(failure);
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
