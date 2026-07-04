import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

class EditorRoutes {
  static const String editor = '/contents/:id/edit';
  static const String editorName = 'editor';

  static GoRoute get route =>
      GoRoute(path: editor, name: editorName, builder: EditorPage.pageBuilder);
}
