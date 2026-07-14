import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../core/theme/editor_colors.dart';
import '../palette_icons.dart';

class PaletteTile extends StatelessWidget {
  const PaletteTile({super.key, required this.descriptor});

  final WidgetDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paletteIconFor(descriptor.type),
            size: 22,
            color: colors.inkPrimary,
          ),
          const SizedBox(height: 6),
          Text(
            descriptor.label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
