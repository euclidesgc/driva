import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/editor_module.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: ProjectsRoutes.projects,
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => AppShell(
        homeRouteName: ProjectsRoutes.projectsName,
        themeButton: const ThemeModeButton(),
        child: child,
      ),
      routes: [
        ProjectsRoutes.route,
        ProjectsRoutes.archivedRoute,
        ContentsRoutes.route,
        EditorRoutes.route,
      ],
    ),
  ],
  onException: (context, state, router) => router.go(ProjectsRoutes.projects),
);
