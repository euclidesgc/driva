import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/history_entry_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_version_into_draft_confirm_dialog.dart';
import 'package:flutter/material.dart';

/// A saída "aplica" do modo de comparação: a versão já foi lida pelo modo,
/// então não há requisição a refazer — só a mesma confirmação de
/// `VersionHistoryDialog._loadToDraft` antes de sobrescrever o rascunho em
/// memória.
///
/// Aplicar encerra o modo (quem faz isso é `applyCandidateToDraft`): com o
/// rascunho igual à versão, os dois lados da comparação passariam a mostrar
/// a mesma coisa.
Future<void> loadFullVersionIntoDraft(
  BuildContext context, {
  required EditorCubit editorCubit,
  required VersionCompareModeCubit compareMode,
}) async {
  final editorState = editorCubit.state;
  if (editorState is! EditorReady) return;
  final compareState = compareMode.state;
  if (compareState is! VersionCompareModeActive) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => LoadVersionIntoDraftConfirmDialog(
      entryLabel: historyEntryPhraseReference(compareState.candidate),
      isDirty: editorState.saveStatus == SaveStatus.dirty,
    ),
  );
  if (confirmed != true) return;

  compareMode.applyCandidateToDraft();
}
