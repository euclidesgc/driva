import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/buttons/buttons.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/content_view_mode.dart';
import 'package:flutter/material.dart';

class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    required this.mode,
    required this.onChanged,
    super.key,
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
