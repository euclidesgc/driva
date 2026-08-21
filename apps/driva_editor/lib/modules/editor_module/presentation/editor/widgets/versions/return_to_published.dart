import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/return_to_published_confirm_dialog.dart';
import 'package:flutter/material.dart';

/// Fluxo do botão `Voltar à versão publicada` (D6): confirma nomeando o que
/// se perde, aplica pelo cubit do modo e, em falha de rede, avisa na barra
/// de status em vez de falhar em silêncio.
Future<void> returnToPublishedFlow(
  BuildContext context, {
  required VersionCompareModeCubit compareCubit,
  required EditorCubit editorCubit,
}) async {
  final editorState = editorCubit.state;
  if (editorState is! EditorReady) return;
  final publishedVersion = editorState.publication.publishedVersion;
  if (publishedVersion == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ReturnToPublishedConfirmDialog(
      publishedVersion: publishedVersion,
      isDirty: editorState.saveStatus == SaveStatus.dirty,
    ),
  );
  if (confirmed != true) return;

  final applied = await compareCubit.returnToPublished();
  if (!applied) editorCubit.notifyLoadPublishedFailed();
}
