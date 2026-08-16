import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/palette_category_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/palette_item.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class PaletteCategorySection extends StatelessWidget {
  const PaletteCategorySection({
    required this.category,
    required this.descriptors,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  final String category;
  final List<WidgetDescriptor> descriptors;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaletteCategoryHeader(
          label: category,
          isExpanded: isExpanded,
          onToggle: onToggle,
          trailing: Text(
            '${descriptors.length}',
            style: TextStyle(
              fontSize: AppTypography.xs,
              color: colors.inkMuted,
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12,
              AppSpacing.none,
              AppSpacing.s12,
              AppSpacing.s8,
            ),
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final descriptor in descriptors)
                  PaletteItem(descriptor: descriptor),
              ],
            ),
          ),
      ],
    );
  }
}
