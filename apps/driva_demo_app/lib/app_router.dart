import 'package:driva_demo_app/modules/published_module/published_module.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRoutes = GoRouter(
  initialLocation: PublishedRoutes.catalog,
  routes: [PublishedRoutes.catalogRoute, PublishedRoutes.contentRoute],
  onException: (context, state, router) => router.go(PublishedRoutes.catalog),
);
