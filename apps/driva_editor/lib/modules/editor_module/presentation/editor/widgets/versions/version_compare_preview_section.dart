import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_base_phrases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_preview_pane.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Os dois previews da comparação (T5, item 50): base à esquerda, candidata
/// à direita no desktop; no compacto, só o lado escolhido em [visibleSide]
/// — o mesmo `VersionCompareSideToggle` compartilhado com a seção de nós
/// exclusivos, nunca duas colunas espremidas. [baseSpec] é o que
/// `VersionCompareCubit` está exibindo como base — reflete o rascunho ao
/// vivo (recalculado a cada mudança do `EditorCubit`) ou a versão no ar
/// quando o usuário troca, nunca uma cópia congelada da abertura.
class VersionComparePreviewSection extends StatelessWidget {
  const VersionComparePreviewSection({
    required this.base,
    required this.baseSpec,
    required this.candidateSpec,
    required this.candidateVersion,
    required this.isCompact,
    required this.visibleSide,
    required this.publishedVersion,
    this.imageUrlResolver,
    super.key,
  });

  final VersionComparisonBase base;
  final ContentSpec baseSpec;
  final ContentSpec candidateSpec;
  final int candidateVersion;
  final bool isCompact;
  final VersionCompareVisibleSide visibleSide;
  final int? publishedVersion;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final basePane = VersionComparePreviewPane(
      label: baseHeadingLabel(base, publishedVersion),
      spec: baseSpec,
      showReadOnlyBadge: base == VersionComparisonBase.published,
      imageUrlResolver: imageUrlResolver,
    );
    final candidatePane = VersionComparePreviewPane(
      label: 'Versão $candidateVersion',
      spec: candidateSpec,
      imageUrlResolver: imageUrlResolver,
    );

    if (!isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: basePane),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: candidatePane),
        ],
      );
    }

    return visibleSide == VersionCompareVisibleSide.base
        ? basePane
        : candidatePane;
  }
}
