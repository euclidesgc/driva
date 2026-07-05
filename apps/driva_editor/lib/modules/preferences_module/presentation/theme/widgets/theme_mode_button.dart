import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_theme_mode.dart';
import '../cubit/theme_cubit.dart';

/// Controle de tema para as top bars: abre um menu com as 3 opcoes
/// (claro/escuro/sistema), dando acesso direto a qualquer uma.
///
/// Cada item tem icone + rotulo pt-BR e a opcao ativa e marcada com um check —
/// a cor nunca e o unico sinal (acessibilidade). O estado atual e anunciado via
/// `Semantics` e pelo tooltip.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeCubit, AppThemeMode>((c) => c.state.mode);
    return Semantics(
      button: true,
      label: 'Tema — atual: ${_labelFor(mode)}',
      child: PopupMenuButton<AppThemeMode>(
        tooltip: 'Tema',
        icon: Icon(_iconFor(mode)),
        initialValue: mode,
        onSelected: (selected) => context.read<ThemeCubit>().setMode(selected),
        itemBuilder: (context) => [
          for (final option in AppThemeMode.values)
            PopupMenuItem<AppThemeMode>(
              value: option,
              child: _ThemeMenuItem(
                icon: _iconFor(option),
                label: _labelFor(option),
                selected: option == mode,
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_outlined,
    AppThemeMode.system => Icons.brightness_auto_outlined,
  };

  static String _labelFor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => 'Claro',
    AppThemeMode.dark => 'Escuro',
    AppThemeMode.system => 'Sistema',
  };
}

class _ThemeMenuItem extends StatelessWidget {
  const _ThemeMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : null;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ),
        if (selected)
          Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
      ],
    );
  }
}
