import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

class ContentsRoutes {
  static const String contents = '/contents';
  static const String contentsName = 'contents';

  static GoRoute get route => GoRoute(
    path: contents,
    name: contentsName,
    builder: ContentListPage.pageBuilder,
  );
}
