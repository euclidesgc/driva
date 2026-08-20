import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_loaded_body.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_failure_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Conteúdo de `VersionCompareDialog` (T5, item 50), sem o invólucro do
/// diálogo — a mesma separação de `VersionReviewBody`, para servir tanto a
/// moldura larga do desktop quanto a tela cheia do compacto.
class VersionCompareBody extends StatelessWidget {
  const VersionCompareBody({required this.isCompact, super.key});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VersionCompareCubit, VersionCompareState>(
      builder: (context, state) => switch (state) {
        VersionCompareLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        final VersionCompareLoadFailure s => VersionReviewFailureView(
          failure: s.failure,
          onRetry: () => context.read<VersionCompareCubit>().load(),
        ),
        final VersionCompareLoaded s => VersionCompareLoadedBody(
          state: s,
          isCompact: isCompact,
        ),
      },
    );
  }
}
