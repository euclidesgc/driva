import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radii.dart';
import '../../../../../../core/theme/app_spacing.dart';

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadii.r8),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.s5),
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
