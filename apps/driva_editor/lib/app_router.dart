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
/// A home de Projetos é a raiz (`/`) — o novo topo da hierarquia. O clique no
/// card de projeto leva à "tela do projeto" (`/projects/:id`, dona do
/// `contents_module`: árvore de categorias + painel de conteúdos). Não há
/// mais lista de conteúdos fora de um projeto — qualquer rota desconhecida
/// (inclui a antiga `/contents`) cai no `onException` e volta para a home.
final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: ProjectsRoutes.projects,
  routes: [ProjectsRoutes.route, ContentsRoutes.route, EditorRoutes.route],
  onException: (context, state, router) => router.go(ProjectsRoutes.projects),
);
