import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Estado exibido quando o servidor responde 404 para uma chave
/// bem-formada (`DrivaLoadCause.notFound`). A rota pública não distingue
/// "slug sem publicação" de "chave publicável inválida" — decisão de
/// segurança da fatia 1 (D-R10.2) — então o texto nomeia as duas causas
/// possíveis em vez de escolher uma.
class ContentNotFoundView extends StatelessWidget {
  const ContentNotFoundView({required this.onRetry, super.key});

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
              Icons.search_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: 'Conteúdo não encontrado',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Conteúdo não encontrado',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Este slug pode não ter sido publicado ainda, ou a chave '
              'publicável configurada não é válida para este projeto.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
