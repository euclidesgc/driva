import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_theme_mode.dart';
import '../cubit/theme_cubit.dart';

/// Controle de alternância de tema: percorre claro → escuro → sistema.
///
/// Cada modo tem ícone, rótulo e tooltip próprios — a cor nunca é o único sinal
/// (acessibilidade). O estado atual é anunciado via `Semantics`.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeCubit, AppThemeMode>((c) => c.state.mode);
    final (icon, label) = _presentationFor(mode);
    final next = _next(mode);

    return Semantics(
      button: true,
      label: 'Tema: $label. Toque para $next.',
      child: IconButton(
        tooltip: 'Tema: $label (toque para $next)',
        icon: Icon(icon),
        onPressed: () => context.read<ThemeCubit>().setMode(_advance(mode)),
      ),
    );
  }

  static (IconData, String) _presentationFor(AppThemeMode mode) =>
      switch (mode) {
        AppThemeMode.light => (Icons.light_mode_outlined, 'claro'),
        AppThemeMode.dark => (Icons.dark_mode_outlined, 'escuro'),
        AppThemeMode.system => (Icons.brightness_auto_outlined, 'sistema'),
      };

  static AppThemeMode _advance(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => AppThemeMode.dark,
    AppThemeMode.dark => AppThemeMode.system,
    AppThemeMode.system => AppThemeMode.light,
  };

  static String _next(AppThemeMode mode) => _presentationFor(_advance(mode)).$2;
}
