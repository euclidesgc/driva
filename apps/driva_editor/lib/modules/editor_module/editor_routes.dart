import 'package:driva_editor/modules/editor_module/presentation/presentation.dart';
import 'package:go_router/go_router.dart';

class EditorRoutes {
  /// Plana e com o `projectId` no path (D1, item 46) — não aninhada sob
  /// `/projects/:id`, para não montar o `ProjectDetailPage` (e os dois
  /// cubits dele) por baixo do editor a cada abertura.
  static const String editor = '/projects/:projectId/contents/:id/edit';
  static const String editorName = 'editor';

  static GoRoute get route =>
      GoRoute(path: editor, name: editorName, builder: EditorPage.pageBuilder);

  /// Sem chrome (D3, item 41): `app_router.dart` instala esta rota como irmã
  /// do `ShellRoute`, no `routes:` do root — nunca dentro dele.
  static const String preview = '/preview/:projectId/:id';
  static const String previewName = 'preview';

  static GoRoute get previewRoute => GoRoute(
    path: preview,
    name: previewName,
    builder: PreviewPage.pageBuilder,
  );

  /// O `start_url` do manifest do preview (D31, item 41): sem ids, existe só
  /// para não dar em 404 ao abrir pelo ícone da tela inicial.
  static const String previewHome = '/preview';
  static const String previewHomeName = 'preview-home';

  static GoRoute get previewHomeRoute => GoRoute(
    path: previewHome,
    name: previewHomeName,
    builder: PreviewHomePage.pageBuilder,
  );
}
