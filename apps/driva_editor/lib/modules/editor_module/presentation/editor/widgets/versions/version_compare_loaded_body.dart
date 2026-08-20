import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_full_version_into_draft.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_diff_view.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_unsafe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

/// O ramo `VersionCompareLoaded` de `VersionCompareBody`: cabeçalho +
/// resultado da comparação, seja o bloqueio de segurança (ID duplicado)
/// seja o diff de verdade — mesmo `Either` que `compareContentSpecs`
/// devolve.
class VersionCompareLoadedBody extends StatelessWidget {
  const VersionCompareLoadedBody({
    required this.state,
    required this.isCompact,
    super.key,
  });

  final VersionCompareLoaded state;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VersionCompareCubit>();
    void loadFullVersion() => loadFullVersionIntoDraft(
      context,
      editorCubit: cubit.editorCubit,
      candidate: state.candidate,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VersionCompareHeader(
            candidate: state.candidate,
            base: state.base,
            hasPublishedVersion: cubit.publishedVersion != null,
            isLoadingPublishedBase: state.isLoadingPublishedBase,
            onBaseChanged: cubit.useBase,
          ),
          const SizedBox(height: AppSpacing.s16),
          switch (state.result) {
            Left(value: final failure) => VersionCompareUnsafeView(
              failure: failure,
              onLoadFullVersion: loadFullVersion,
            ),
            Right(value: final result) => VersionCompareDiffView(
              result: result,
              baseSpec: state.baseSpec,
              candidateSpec: state.candidate.spec,
              canCopy: state.base == VersionComparisonBase.draft,
              isCompact: isCompact,
              onCopy: cubit.copyNodeProperties,
              onLoadFullVersion: loadFullVersion,
            ),
          },
        ],
      ),
    );
  }
}
