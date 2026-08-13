import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/prop_icons.dart';
import 'package:driva_editor/core/widgets/buttons/toggle_button.dart';
import 'package:flutter/material.dart';

class EdgeInsetsModeBar extends StatelessWidget {
  const EdgeInsetsModeBar({
    required this.isUniform,
    required this.onChanged,
    super.key,
  });

  final bool isUniform;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ToggleButton(
          tooltip: 'Todos os lados',
          icon: PropIcons.resolve('edgeUniform')!,
          selected: isUniform,
          onPressed: () => onChanged(true),
        ),
        const SizedBox(width: AppSpacing.s2),
        ToggleButton(
          tooltip: 'Lado a lado',
          icon: PropIcons.resolve('edgeIndividual')!,
          selected: !isUniform,
          onPressed: () => onChanged(false),
        ),
      ],
    );
  }
}
