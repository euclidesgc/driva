import 'dart:async';
import 'package:driva_editor/modules/editor_module/editor_routes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/canvas_compare_binding.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_full_version_into_draft.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/return_to_published.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_unsafe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

class CanvasArea extends StatelessWidget {
  const CanvasArea({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    // D7: alcança o `EditorLayoutController` pelo soquete, não por um sexto
    // parâmetro de construtor a partir de `EditorWorkspace` (`VR-16-02`).
    final layoutController = EditorLayoutScope.of(context)!;
    return BlocSelector<
      EditorCubit,
      EditorState,
      ({
        DevicePreset device,
        double zoom,
        bool fitToWindow,
        bool ready,
        bool isPublished,
      })
    >(
      selector: (state) => state is EditorReady
          ? (
              device: state.device,
              zoom: state.zoom,
              fitToWindow: state.fitToWindow,
              ready: true,
              isPublished: state.publication.isPublished,
            )
          : (
              device: DevicePreset.smartphone,
              zoom: 0.9,
              fitToWindow: true,
              ready: false,
              isPublished: false,
            ),
      builder: (context, vm) => ValueListenableBuilder<bool>(
        valueListenable: layoutController.isFullscreen,
        builder: (context, isFullscreen, _) => CanvasCompareBinding(
          builder: (context, compareState, mode) => CanvasPanel(
            device: vm.device,
            zoom: vm.zoom,
            fitToWindow: vm.fitToWindow,
            onSelect: cubit.selectNode,
            onChangeDevice: cubit.changeDevice,
            onChangeZoom: cubit.changeZoom,
            onToggleFitToWindow: cubit.toggleFitToWindow,
            imageUrlResolver: imageUrlResolver,
            onOpenPreview: vm.ready
                ? () => _openPreviewDialog(context, cubit)
                : null,
            isFullscreen: isFullscreen,
            onToggleFullscreen: layoutController.toggleFullscreen,
            onDropOnDevice: (payload) {
              final state = cubit.state;
              if (state is! EditorReady) return;
              // Conteúdo vazio: o nó vira a raiz (alvo null resolve isso).
              _dispatch(cubit, payload, state.document.root?.id);
            },
            onDropOnNode: (payload, targetId) =>
                _dispatch(cubit, payload, targetId),
            onReturnToPublished: switch (compareState) {
              VersionCompareModeActive() when mode != null && vm.isPublished =>
                () => unawaited(
                  returnToPublishedFlow(
                    context,
                    compareCubit: mode,
                    editorCubit: cubit,
                  ),
                ),
              _ => null,
            },
            compareCandidateVersion: switch (compareState) {
              final VersionCompareModeActive s => s.candidate.version,
              _ => null,
            },
            compareBuilder: switch (compareState) {
              final VersionCompareModeActive s when mode != null =>
                (scale) => VersionCompareMockPane(
                  device: vm.device,
                  effectiveScale: scale,
                  spec: s.candidate.spec,
                  candidateVersion: s.candidate.version,
                  imageUrlResolver: imageUrlResolver,
                  onOlder: mode.stepOlder,
                  onNewer: mode.stepNewer,
                  onClose: mode.exit,
                  unsafeView: s.result.fold(
                    (failure) => VersionCompareUnsafeView(
                      failure: failure,
                      onLoadFullVersion: () => unawaited(
                        loadFullVersionIntoDraft(
                          context,
                          editorCubit: cubit,
                          candidate: s.candidate,
                        ),
                      ),
                    ),
                    (_) => null,
                  ),
                ),
              _ => null,
            },
          ),
        ),
      ),
    );
  }

  /// A URL vem da própria origem do editor (`Uri.base`), não de `AppConfig`
  /// (que aponta para a API, não para este front). O caminho é o mesmo que
  /// [EditorRoutes.previewRoute] resolve — nada de string de rota duplicada.
  void _openPreviewDialog(BuildContext context, EditorCubit cubit) {
    final state = cubit.state;
    if (state is! EditorReady) return;
    final location = GoRouter.of(context).namedLocation(
      EditorRoutes.previewName,
      pathParameters: {
        'projectId': cubit.projectId,
        'id': state.document.id,
      },
    );
    final url = '${Uri.base.origin}$location';
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => PreviewShareDialog(url: url),
      ),
    );
  }

  void _dispatch(EditorCubit cubit, DragPayload payload, String? targetId) {
    switch (payload) {
      case PaletteDragPayload(:final type):
        cubit.addNode(type, targetId: targetId);
      case NodeDragPayload(:final nodeId) when targetId != null:
        cubit.moveNode(nodeId, targetId);
      case NodeDragPayload():
        break;
    }
  }
}
