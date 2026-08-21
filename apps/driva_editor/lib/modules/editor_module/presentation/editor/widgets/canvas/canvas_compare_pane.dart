import 'dart:async';

import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_mock_pane.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_full_version_into_draft.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_unsafe_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// O pane da direita do modo de comparação: assina [VersionCompareModeCubit]
/// por conta própria, em vez de receber o spec da candidata pelo
/// construtor — é o que mantém o mock do rascunho fora deste subtree,
/// livre para ficar parado enquanto só a candidata muda (ou vice-versa).
class CanvasComparePane extends StatelessWidget {
  const CanvasComparePane({
    required this.device,
    required this.effectiveScale,
    required this.cubit,
    required this.editorCubit,
    this.imageUrlResolver,
    super.key,
  });

  final DevicePreset device;
  final double effectiveScale;
  final VersionCompareModeCubit cubit;
  final EditorCubit editorCubit;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VersionCompareModeCubit, VersionCompareModeState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is! VersionCompareModeActive) {
          return const SizedBox.shrink();
        }
        return VersionCompareMockPane(
          device: device,
          effectiveScale: effectiveScale,
          spec: state.candidate.spec,
          candidateVersion: state.candidate.version,
          imageUrlResolver: imageUrlResolver,
          onOlder: cubit.stepOlder,
          onNewer: cubit.stepNewer,
          onClose: cubit.exit,
          unsafeView: state.result.fold(
            (failure) => VersionCompareUnsafeView(
              failure: failure,
              onLoadFullVersion: () => unawaited(
                loadFullVersionIntoDraft(
                  context,
                  editorCubit: editorCubit,
                  candidate: state.candidate,
                ),
              ),
            ),
            (_) => null,
          ),
        );
      },
    );
  }
}
