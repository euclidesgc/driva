import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'modules/contents_module/contents_module.dart';
import 'modules/editor_module/editor_module.dart';
import 'modules/projects_module/projects_module.dart';

/// Root navigator key: available for routes that must cover any future shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Flat routes (desktop web — no mobile tab shell).
///
/// The router only knows the modules' public barrels and mounts their
/// `XRoutes.route`. Named routes always; never `extra:` (lost on web refresh).
///
/// A home de Projetos é a raiz (`/`) — o novo topo da hierarquia. A rota de
/// conteúdos (`/contents`) segue existindo: o card de projeto ainda leva
/// para lá (troca de escopo x-project-id fica para docs/08 P2).
final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: ProjectsRoutes.projects,
  routes: [ProjectsRoutes.route, ContentsRoutes.route, EditorRoutes.route],
  onException: (context, state, router) => router.go(ProjectsRoutes.projects),
);
