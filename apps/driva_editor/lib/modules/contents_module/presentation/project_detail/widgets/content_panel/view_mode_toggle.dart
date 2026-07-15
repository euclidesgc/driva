import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radii.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import 'content_view_mode.dart';

class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ContentViewMode mode;
  final ValueChanged<ContentViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadii.r9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ToggleButton(
            tooltip: 'Grade',
            icon: Icons.grid_view_rounded,
            selected: mode == ContentViewMode.grid,
            onPressed: () => onChanged(ContentViewMode.grid),
          ),
          ToggleButton(
            tooltip: 'Lista',
            icon: Icons.view_list_rounded,
            selected: mode == ContentViewMode.list,
            onPressed: () => onChanged(ContentViewMode.list),
          ),
        ],
      ),
    );
  }
}
