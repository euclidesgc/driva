import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_durations.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/preview_scroll_behavior.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/widgets/last_saved_pill.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/widgets/preview_refresh_failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart' show ContentSpec;
import 'package:sdui_flutter/sdui_flutter.dart';

/// A tela do preview: o conteúdo desenhado pelo renderer real, sem seleção de
/// nó (`nodeWrapper` ausente) e sem diagnósticos — `SduiView.content` já nasce
/// com `showDiagnostics: false` por padrão, e é isso que a D17 pede: visual,
/// não interativo, sem vazar detalhe de infraestrutura para quem recebe o
/// link. A pílula da D4 flutua no rodapé; o gesto de atualizar (D30) é o
/// `RefreshIndicator` em volta do conteúdo.
class PreviewContent extends StatelessWidget {
  const PreviewContent({
    required this.spec,
    required this.fetchedAt,
    required this.onRefresh,
    this.refreshFailure,
    this.imageUrlResolver,
    super.key,
  });

  final ContentSpec spec;
  final DateTime fetchedAt;
  final Future<void> Function() onRefresh;
  final Failure? refreshFailure;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ScrollConfiguration(
            behavior: const PreviewScrollBehavior(),
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SduiView.content(
                      spec,
                      imageUrlResolver: imageUrlResolver,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.s16,
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppDurations.quick,
              child: refreshFailure == null
                  ? const SizedBox.shrink()
                  : PreviewRefreshFailureBanner(failure: refreshFailure!),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          bottom: AppSpacing.s16,
          child: IgnorePointer(
            child: Center(child: LastSavedPill(fetchedAt: fetchedAt)),
          ),
        ),
      ],
    );
  }
}
