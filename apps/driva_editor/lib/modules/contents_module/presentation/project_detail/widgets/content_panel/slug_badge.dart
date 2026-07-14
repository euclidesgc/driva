import 'package:flutter/material.dart';

/// Slug em destaque: ícone + rótulo textual "slug" (a cor não é o único
/// sinal).
class SlugBadge extends StatelessWidget {
  const SlugBadge({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Slug do conteúdo: $slug',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                slug,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
