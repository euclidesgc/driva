import 'package:driva_editor/modules/editor_module/presentation/presentation.dart';
import 'package:go_router/go_router.dart';

class EditorRoutes {
  static const String editor = '/contents/:id/edit';
  static const String editorName = 'editor';

  static GoRoute get route =>
      GoRoute(path: editor, name: editorName, builder: EditorPage.pageBuilder);
}
