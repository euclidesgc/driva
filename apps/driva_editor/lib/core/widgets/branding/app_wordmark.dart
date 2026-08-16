import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;

  /// Faixa estreita da top bar (D35): devolve os ~90px de " Builder" sem
  /// perder a marca — "Driva" sozinho continua legível.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // " Builder" acompanha o brilho do tema (onSurface): tinta escura no claro,
    // clara no escuro — nao some sobre o canvas dark. "Driva" mantem o laranja
    // da marca, que contrasta nos dois temas.
    final label = Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: AppTypography.xl,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1,
        ),
        children: [
          const TextSpan(
            text: 'Driva',
            style: TextStyle(color: AppTheme.primary),
          ),
          if (!compact)
            TextSpan(
              text: ' Builder',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
        ],
      ),
    );

    if (onTap == null) return label;

    final semanticLabel = compact
        ? 'Driva, ir para a home'
        : 'Driva Builder, ir para a home';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: 'Ir para a home',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.r8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.s6,
            ),
            child: label,
          ),
        ),
      ),
    );
  }
}
