import 'dart:async';

import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/widgets/feedback/feedback.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_history_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_version_into_draft_confirm_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_failure_message.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// A lista paginada de versões (padrão de scroll infinito do item 16:
/// `NotificationListener` + rodapé "Carregando mais…"). `editorCubit` é quem
/// de fato troca o documento ao carregar uma versão ou aplicar uma cópia
/// seletiva; este diálogo só lista e delega `Ver`/`Comparar`/`Carregar no
/// rascunho` (item 50).
class VersionHistoryDialog extends StatelessWidget {
  const VersionHistoryDialog({
    required this.editorCubit,
    required this.getContentVersionUseCase,
    this.imageUrlResolver,
    super.key,
  });

  final EditorCubit editorCubit;
  final GetContentVersionUseCase getContentVersionUseCase;
  final SduiImageUrlResolver? imageUrlResolver;

  static const _prefetchExtent = 200.0;

  Future<void> _view(BuildContext context, int version) async {
    final contentId = context.read<VersionHistoryCubit>().contentId;
    final reviewCubit = VersionReviewCubit(
      getContentVersionUseCase: getContentVersionUseCase,
      contentId: contentId,
      version: version,
    );
    unawaited(reviewCubit.load());

    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: reviewCubit,
        child: VersionReviewDialog(imageUrlResolver: imageUrlResolver),
      ),
    );
    await reviewCubit.close();
  }

  Future<void> _loadToDraft(BuildContext context, int version) async {
    final contentId = context.read<VersionHistoryCubit>().contentId;
    final result = await getContentVersionUseCase(contentId, version);
    if (!context.mounted) return;

    final loaded = result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(versionFailureMessage(failure))),
        );
        return null;
      },
      (loadedVersion) => loadedVersion,
    );
    if (loaded == null) return;

    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => LoadVersionIntoDraftConfirmDialog(
        version: version,
        isDirty: editorState.saveStatus == SaveStatus.dirty,
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    editorCubit.loadVersionIntoDraft(loaded.spec, version: loaded.version);
    Navigator.of(context).pop();
  }

  Future<void> _compare(BuildContext context, int candidateVersion) async {
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;
    final contentId = context.read<VersionHistoryCubit>().contentId;
    final compareCubit = VersionCompareCubit(
      getContentVersionUseCase: getContentVersionUseCase,
      editorCubit: editorCubit,
      contentId: contentId,
      candidateVersion: candidateVersion,
    );
    unawaited(compareCubit.load());

    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: compareCubit,
        child: VersionCompareDialog(imageUrlResolver: imageUrlResolver),
      ),
    );
    await compareCubit.close();
  }

  bool _onScroll(BuildContext context, ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - _prefetchExtent) {
      unawaited(context.read<VersionHistoryCubit>().loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Histórico de versões'),
      content: SizedBox(
        width: AppSizes.versionHistoryDialogWidth,
        height: AppSizes.versionHistoryListHeight,
        child: BlocBuilder<VersionHistoryCubit, VersionHistoryState>(
          builder: (context, state) => switch (state) {
            VersionHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            VersionHistoryLoadFailure() => const Center(
              child: Text('Não foi possível carregar o histórico.'),
            ),
            final VersionHistoryLoaded s when s.versions.isEmpty =>
              const Center(child: Text('Nenhuma versão publicada ainda.')),
            final VersionHistoryLoaded s =>
              NotificationListener<ScrollNotification>(
                onNotification: (notification) =>
                    _onScroll(context, notification),
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: s.isLoadingMore
                            ? AppSizes.loadingMoreFooterInset
                            : 0,
                      ),
                      itemCount: s.versions.length,
                      itemBuilder: (context, index) {
                        final version = s.versions[index];
                        return VersionRow(
                          version: version,
                          isPublished: version.version == s.publishedVersion,
                          onView: (v) => _view(context, v),
                          onLoadToDraft: (v) => _loadToDraft(context, v),
                          onCompare: (v) => _compare(context, v),
                        );
                      },
                    ),
                    if (s.isLoadingMore)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: AppSpacing.s8,
                        child: LoadingMoreFooter(
                          semanticsLabel: 'Carregando mais versões',
                        ),
                      ),
                  ],
                ),
              ),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
