import 'package:driva_editor/modules/editor_module/presentation/presentation.dart';
import 'package:go_router/go_router.dart';

class EditorRoutes {
  static const String editor = '/contents/:id/edit';
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
}
