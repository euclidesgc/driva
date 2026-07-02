import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

class PagesRoutes {
  static const String pages = '/pages';
  static const String pagesName = 'pages';

  static GoRoute get route =>
      GoRoute(path: pages, name: pagesName, builder: PageListPage.pageBuilder);
}
