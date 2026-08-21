import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:flutter/material.dart';

/// Marcador de diff na linha da árvore (F2 do plano T5b): numa linha o
/// espaço é curto, então é ícone + tooltip + `Semantics`, sem o texto do
/// chip — o texto por extenso continua no Inspector, onde há largura.
class TreeRowDiffMarker extends StatelessWidget {
  const TreeRowDiffMarker({required this.kind, super.key});

  final VersionCompareMarkerKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final message = kind.isReadOnly
        ? '${kind.label} — somente leitura nesta versão do Driva'
        : kind.label;
    return Tooltip(
      message: message,
      child: Icon(
        kind.icon,
        size: AppIconSizes.s16,
        color: kind.tone(colors),
        semanticLabel: message,
      ),
    );
  }
}
