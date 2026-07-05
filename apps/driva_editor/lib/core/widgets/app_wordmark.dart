import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // " Builder" acompanha o brilho do tema (onSurface): tinta escura no claro,
    // clara no escuro — nao some sobre o canvas dark. "Driva" mantem o laranja
    // da marca, que contrasta nos dois temas.
    final label = Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1,
        ),
        children: [
          const TextSpan(
            text: 'Driva',
            style: TextStyle(color: AppTheme.primary),
          ),
          TextSpan(
            text: ' Builder',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );

    if (onTap == null) return label;

    return Semantics(
      button: true,
      label: 'Driva Builder, ir para a home',
      child: Tooltip(
        message: 'Ir para a home',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: label,
          ),
        ),
      ),
    );
  }
}
