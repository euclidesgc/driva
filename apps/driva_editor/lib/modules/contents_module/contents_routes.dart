import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

/// A "tela do projeto" (árvore de categorias + painel de conteúdos) é a rota
/// dona deste módulo agora: `/projects/:id`. O clique no card de projeto
/// (`projects_module`) navega para cá; o clique no conteúdo segue para o
/// Construtor (`editor_module`, rota `/contents/:id/edit`).
class ContentsRoutes {
  static const String projectDetail = '/projects/:id';
  static const String projectDetailName = 'project-detail';

  static GoRoute get route => GoRoute(
    path: projectDetail,
    name: projectDetailName,
    builder: ProjectDetailPage.pageBuilder,
  );
}
