import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_version_into_draft_confirm_dialog.dart';
import 'package:flutter/material.dart';

/// Alternativa segura oferecida por `VersionCompareUnsafeView` e
/// `VersionCompareFullLoadBanner` (T5, item 50): a versão já foi lida pelo
/// diálogo de comparação, então não há GET a refazer — só a mesma
/// confirmação de `VersionHistoryDialog._loadToDraft` antes de aplicar em
/// memória e fechar o diálogo por cima.
Future<void> loadFullVersionIntoDraft(
  BuildContext context, {
  required EditorCubit editorCubit,
  required LoadedContentVersion candidate,
}) async {
  final editorState = editorCubit.state;
  if (editorState is! EditorReady) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => LoadVersionIntoDraftConfirmDialog(
      version: candidate.version,
      isDirty: editorState.saveStatus == SaveStatus.dirty,
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  editorCubit.loadVersionIntoDraft(candidate.spec, version: candidate.version);
  Navigator.of(context).pop();
}
