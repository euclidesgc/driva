import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'modules/pages_module/pages_module.dart';

/// Root navigator key: available for routes that must cover any future shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Flat routes (desktop web — no mobile tab shell).
///
/// The router only knows the modules' public barrels and mounts their
/// `XRoutes.route`. Named routes always; never `extra:` (lost on web refresh).
final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: PagesRoutes.pages,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => PagesRoutes.pages,
    ),
    PagesRoutes.route,
    // TODO(fase-4): EditorRoutes.route
  ],
  onException: (context, state, router) => router.go(PagesRoutes.pages),
);
