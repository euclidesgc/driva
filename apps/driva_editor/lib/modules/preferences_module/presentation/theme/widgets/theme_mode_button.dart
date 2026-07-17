import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/presentation/theme/cubit/theme_cubit.dart';
import 'package:driva_editor/modules/preferences_module/presentation/theme/widgets/theme_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = context.select<ThemeCubit, AppThemeMode>((c) => c.state.mode);
    return Semantics(
      button: true,
      label: 'Tema — atual: ${_labelFor(mode)}',
      child: PopupMenuButton<AppThemeMode>(
        tooltip: 'Tema',
        icon: Icon(_iconFor(mode), color: theme.colorScheme.onSurface),
        iconColor: theme.colorScheme.onSurface,
        color: theme.colorScheme.surface,
        initialValue: mode,
        onSelected: (selected) => context.read<ThemeCubit>().setMode(selected),
        itemBuilder: (context) => [
          for (final option in AppThemeMode.values)
            PopupMenuItem<AppThemeMode>(
              value: option,
              child: ThemeMenuItem(
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
