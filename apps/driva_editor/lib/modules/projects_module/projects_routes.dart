import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

class ProjectsRoutes {
  static const String projects = '/';
  static const String projectsName = 'projects';

  static GoRoute get route => GoRoute(
    path: projects,
    name: projectsName,
    builder: ProjectListPage.pageBuilder,
  );
}
