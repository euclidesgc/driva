import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'modules/contents_module/contents_module.dart';
import 'modules/editor_module/editor_module.dart';

/// Root navigator key: available for routes that must cover any future shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Flat routes (desktop web — no mobile tab shell).
///
/// The router only knows the modules' public barrels and mounts their
/// `XRoutes.route`. Named routes always; never `extra:` (lost on web refresh).
final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: ContentsRoutes.contents,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => ContentsRoutes.contents),
    ContentsRoutes.route,
    EditorRoutes.route,
  ],
  onException: (context, state, router) => router.go(ContentsRoutes.contents),
);
