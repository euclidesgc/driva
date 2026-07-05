import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection.dart';
import 'modules/preferences_module/preferences_module.dart';

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
