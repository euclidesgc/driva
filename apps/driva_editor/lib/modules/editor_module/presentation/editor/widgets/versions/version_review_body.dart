import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_failure_view.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_snapshot_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Conteúdo de `VersionReviewDialog`, sem o invólucro do diálogo — para que
/// a mesma árvore sirva a moldura estreita do desktop e a tela cheia do
/// compacto (T3, item 50).
class VersionReviewBody extends StatelessWidget {
  const VersionReviewBody({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VersionReviewCubit, VersionReviewState>(
      builder: (context, state) => switch (state) {
        VersionReviewLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        final VersionReviewLoadFailure s => VersionReviewFailureView(
          failure: s.failure,
          onRetry: () => context.read<VersionReviewCubit>().load(),
        ),
        final VersionReviewLoaded s => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VersionReviewHeader(entry: s.entry),
            const SizedBox(height: AppSpacing.s12),
            Expanded(
              child: VersionSnapshotPreview(
                spec: s.entry.spec,
                imageUrlResolver: imageUrlResolver,
              ),
            ),
          ],
        ),
      },
    );
  }
}
