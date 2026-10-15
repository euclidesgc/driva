import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// O valor ligado de um campo: "Fonte · caminho". Tocar reabre o diálogo de
/// ligação; o `×` remove a ligação e devolve o valor fixo.
class BindingChip extends StatelessWidget {
  const BindingChip({
    required this.binding,
    required this.onTap,
    required this.onRemove,
    this.sources = bindingSourceCatalog,
    super.key,
  });

  static const removeLabel = 'Remover ligação';
  static const _iconSize = 14.0;

  final BoundPropValue binding;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final List<BindingSource> sources;

  String get _sourceLabel {
    for (final source in sources) {
      if (source.id == binding.source) return source.label;
    }
    return binding.isLegacy ? 'Expressão' : binding.source;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final radius = BorderRadius.circular(AppRadii.r6);
    return Material(
      color: colors.primaryTint,
      borderRadius: radius,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s6,
                ),
                child: Text(
                  '$_sourceLabel · ${binding.path}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.base,
                    color: colors.inkPrimary,
                  ),
                ),
              ),
            ),
          ),
          Tooltip(
            message: removeLabel,
            child: Semantics(
              button: true,
              label: removeLabel,
              child: InkWell(
                onTap: onRemove,
                borderRadius: radius,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.s6),
                  child: Icon(Icons.close, size: _iconSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
