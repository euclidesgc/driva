import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

class ContentsRoutes {
  static const String projectDetail = '/projects/:id';
  static const String projectDetailName = 'project-detail';

  static GoRoute get route => GoRoute(
    path: projectDetail,
    name: projectDetailName,
    builder: ProjectDetailPage.pageBuilder,
  );
}
