import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

enum DimensionUnit { pixels, percent }

/// `PX` / `%` como texto, no padrão do FlutterFlow: o ativo em destaque, o
/// outro apagado. Peso e cor carregam a informação junto — cor não é o único
/// sinal.
class DimensionUnitToggle extends StatelessWidget {
  const DimensionUnitToggle({
    required this.unit,
    required this.onChanged,
    super.key,
  });

  final DimensionUnit unit;
  final ValueChanged<DimensionUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UnitLabel(
          text: 'PX',
          tooltip: 'Medir em pixels',
          isSelected: unit == DimensionUnit.pixels,
          onPressed: () => onChanged(DimensionUnit.pixels),
        ),
        const SizedBox(width: AppSpacing.s4),
        _UnitLabel(
          text: '%',
          tooltip: 'Medir em porcentagem do pai',
          isSelected: unit == DimensionUnit.percent,
          onPressed: () => onChanged(DimensionUnit.percent),
        ),
      ],
    );
  }
}

class _UnitLabel extends StatelessWidget {
  const _UnitLabel({
    required this.text,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  final String text;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTypography.sm,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? colors.inkPrimary : colors.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
