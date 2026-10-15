import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/prop_value_type_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/editing_lock.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Uma fonte na lista do seletor de variável: o nome e o tipo que ela entrega.
///
/// A fonte que não alimenta o tipo do campo continua na lista, esmaecida e
/// inerte, com a dica do motivo: some-la esconderia da pessoa que ela existe.
class BindingSourceTile extends StatelessWidget {
  const BindingSourceTile({
    required this.source,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  static const incompatibleHint = 'Tipo incompatível';

  final BindingSource source;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final typeLabel = propValueTypeLabel(source.outputType);
    final radius = BorderRadius.circular(AppRadii.r6);

    final tile = Material(
      color: isSelected ? colors.primaryTint : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  source.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.base,
                    color: colors.inkPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                typeLabel,
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: colors.inkMuted,
                ),
              ),
              // A seleção não pode depender só da cor do fundo.
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.s8),
                const Icon(
                  Icons.check,
                  size: AppIconSizes.s16,
                  color: AppTheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label: '${source.label}, $typeLabel',
      hint: isEnabled ? null : incompatibleHint,
      onTap: isEnabled ? onTap : null,
      excludeSemantics: true,
      child: isEnabled
          ? tile
          : Tooltip(
              message: incompatibleHint,
              child: Opacity(opacity: EditingLock.lockedOpacity, child: tile),
            ),
    );
  }
}
