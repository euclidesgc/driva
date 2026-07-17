import 'package:driva_editor/app_router.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Driva Builder',
            debugShowCheckedModeBanner: false,
            routerConfig: appRoutes,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.mode.materialThemeMode,
          );
        },
      ),
    );
  }
}
