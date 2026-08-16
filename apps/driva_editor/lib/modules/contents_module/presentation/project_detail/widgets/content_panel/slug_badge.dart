import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Slug em destaque: ícone + rótulo textual "slug" (a cor não é o único
/// sinal).
///
/// Defende-se por dentro, porque nenhum chamador pode garantir espaço:
/// abaixo de [_iconThreshold] o ícone cede lugar ao texto. Abaixo de
/// [minimumWidth], o badge insiste no próprio piso via [UnconstrainedBox] —
/// um `ConstrainedBox` sozinho não basta: o `enforce()` que ele usa clampa o
/// `minWidth` contra o `maxWidth` recebido do pai, e o "piso" nunca supera o
/// que já foi oferecido (colapsa junto, em silêncio). O `UnconstrainedBox`
/// só entra quando o espaço já está abaixo do piso — com espaço de sobra, o
/// texto continua elidindo normalmente dentro do que foi dado, sem pedir
/// mais do que precisa.
class SlugBadge extends StatelessWidget {
  const SlugBadge({required this.slug, super.key});

  final String slug;

  static const double _iconThreshold = 70;

  /// Piso do badge com o ícone já escondido: padding dos dois lados mais o
  /// ícone e o vão que cederiam lugar ao texto — a mesma soma que o `build`
  /// usa para montar o Container e o Row, então nunca diverge dela. Público
  /// porque a F9 testa legibilidade contra este número.
  static const double minimumWidth =
      (AppSpacing.s10 * 2) + AppIconSizes.s14 + AppSpacing.s5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Slug do conteúdo: $slug',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIcon = constraints.maxWidth >= _iconThreshold;
          final badge = Container(
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
                if (showIcon) ...[
                  Icon(
                    Icons.tag,
                    size: AppIconSizes.s14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.s5),
                ],
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
          );

          if (constraints.maxWidth >= minimumWidth) return badge;

          return UnconstrainedBox(
            constrainedAxis: Axis.vertical,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(
                width: minimumWidth,
              ),
              child: badge,
            ),
          );
        },
      ),
    );
  }
}
