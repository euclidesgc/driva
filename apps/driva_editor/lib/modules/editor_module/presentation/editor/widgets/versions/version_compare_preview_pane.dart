import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_readonly_badge.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_snapshot_preview.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Um lado rotulado de `VersionComparePreviewSection` (T5, item 50):
/// reaproveita o `VersionSnapshotPreview` inerte do T3
/// (`AbsorbPointer` + `FocusScope(canRequestFocus: false)`) — nenhum dos
/// dois previews da comparação é interativo. O selo "Somente leitura"
/// declara que a versão exibida é imutável — verdade para a candidata e
/// para a base quando ela é a versão no ar, mas falso quando a base é o
/// rascunho (o rascunho é editável; só esta prévia congelada é que não é),
/// por isso [showReadOnlyBadge] deixa o chamador omiti-lo.
class VersionComparePreviewPane extends StatelessWidget {
  const VersionComparePreviewPane({
    required this.label,
    required this.spec,
    this.showReadOnlyBadge = true,
    this.imageUrlResolver,
    super.key,
  });

  final String label;
  final ContentSpec spec;
  final bool showReadOnlyBadge;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            if (showReadOnlyBadge) const VersionReadonlyBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: AppSizes.versionComparePreviewPaneHeight,
          child: VersionSnapshotPreview(
            spec: spec,
            imageUrlResolver: imageUrlResolver,
          ),
        ),
      ],
    );
  }
}
