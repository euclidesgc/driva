import 'package:driva_editor/modules/projects_module/presentation/presentation.dart';
import 'package:go_router/go_router.dart';

class ProjectsRoutes {
  static const String projects = '/';
  static const String projectsName = 'projects';

  static const String archived = '/projects/archived';
  static const String archivedName = 'projects-archived';

  static GoRoute get route => GoRoute(
    path: projects,
    name: projectsName,
    builder: ProjectListPage.pageBuilder,
  );

  static GoRoute get archivedRoute => GoRoute(
    path: archived,
    name: archivedName,
    builder: ArchivedProjectsPage.pageBuilder,
  );
}
