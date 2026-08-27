import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Estado exibido para falhas de conexão ou servidor: exceção de rede
/// (`DrivaLoadCause.network`), resposta de erro (`serverError`) ou spec que
/// não passou no parse do kernel (`invalidSpec`). Não cobre chave ausente
/// nem slug/chave inválidos — esses têm views próprias.
class ContentErrorView extends StatelessWidget {
  const ContentErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppIconSizes.emptyState,
              color: theme.colorScheme.error,
              semanticLabel: 'Falha de conexão ou servidor',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não foi possível carregar o conteúdo agora — pode ser sua '
              'conexão ou o servidor.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
