import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_full_version_into_draft.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_diff_view.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_preview_section.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_side_toggle.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_unsafe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:sdui_flutter/sdui_flutter.dart';

/// O ramo `VersionCompareLoaded` de `VersionCompareBody`: cabeçalho, o par
/// de previews (sempre visível — é informação segura mesmo quando ID
/// duplicado bloqueia o diff) e o resultado da comparação, seja o bloqueio
/// de segurança seja o diff de verdade — mesmo `Either` que
/// `compareContentSpecs` devolve. `_visibleSide` é o único estado próprio
/// desta classe: no compacto, decide ao mesmo tempo qual preview e qual
/// coluna de nós exclusivos aparecem, então mora aqui, no ancestral comum
/// das duas seções, não em cada uma.
class VersionCompareLoadedBody extends StatefulWidget {
  const VersionCompareLoadedBody({
    required this.state,
    required this.isCompact,
    this.imageUrlResolver,
    super.key,
  });

  final VersionCompareLoaded state;
  final bool isCompact;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  State<VersionCompareLoadedBody> createState() =>
      _VersionCompareLoadedBodyState();
}

class _VersionCompareLoadedBodyState extends State<VersionCompareLoadedBody> {
  VersionCompareVisibleSide _visibleSide = VersionCompareVisibleSide.base;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VersionCompareCubit>();
    final state = widget.state;
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
          if (widget.isCompact) ...[
            VersionCompareSideToggle(
              selected: _visibleSide,
              onChanged: (side) => setState(() => _visibleSide = side),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          VersionComparePreviewSection(
            base: state.base,
            baseSpec: state.baseSpec,
            candidateSpec: state.candidate.spec,
            candidateVersion: state.candidate.version,
            isCompact: widget.isCompact,
            visibleSide: _visibleSide,
            publishedVersion: cubit.publishedVersion,
            imageUrlResolver: widget.imageUrlResolver,
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
              isCompact: widget.isCompact,
              visibleSide: _visibleSide,
              base: state.base,
              publishedVersion: cubit.publishedVersion,
              onCopy: cubit.copyNodeProperties,
              onLoadFullVersion: loadFullVersion,
            ),
          },
        ],
      ),
    );
  }
}
