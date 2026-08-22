import 'dart:async';

import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_candidate_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_draft_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_full_version_into_draft.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A barra única do modo de comparação lado a lado: atravessa toda a largura
/// da área de comparação, com o rascunho identificado na metade esquerda e a
/// candidata (versão, selo, navegação, carregar e fechar) na direita — as
/// duas metades alinhadas aos mocks que ficam logo abaixo.
///
/// Substitui a antiga `VersionCompareCandidateBar` isolada só sobre o pane da
/// direita, que deixava o lado do rascunho sem identificação nenhuma. Some
/// junto com o modo (T5b) — na faixa estreita de um mock por vez, quem
/// identifica os lados é `CanvasCompareSideToggle`.
class VersionCompareModeBar extends StatelessWidget {
  const VersionCompareModeBar({
    required this.cubit,
    required this.editorCubit,
    super.key,
  });

  final VersionCompareModeCubit cubit;
  final EditorCubit editorCubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VersionCompareModeCubit, VersionCompareModeState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is! VersionCompareModeActive) {
          return const SizedBox.shrink();
        }
        void loadFullVersion() => unawaited(
          loadFullVersionIntoDraft(
            context,
            editorCubit: editorCubit,
            compareMode: cubit,
          ),
        );
        return Row(
          children: [
            const Expanded(child: VersionCompareDraftLabel()),
            const SizedBox(width: AppSizes.canvasCompareGutter),
            Expanded(
              child: VersionCompareCandidateBar(
                candidate: state.candidate,
                onOlder: state.canNavigateHistory ? cubit.stepOlder : null,
                onNewer: state.canNavigateHistory ? cubit.stepNewer : null,
                onLoadFullVersion: loadFullVersion,
                onClose: cubit.exit,
              ),
            ),
          ],
        );
      },
    );
  }
}
