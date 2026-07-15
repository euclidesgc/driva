import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../../device_preset.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    super.key,
    required this.device,
    required this.zoom,
    required this.onChangeDevice,
    required this.onChangeZoom,
  });

  final DevicePreset device;
  final double zoom;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          SegmentedButton<DevicePreset>(
            segments: [
              for (final preset in DevicePreset.values)
                ButtonSegment(
                  value: preset,
                  tooltip:
                      '${preset.label} (${preset.width.toInt()}×${preset.height.toInt()})',
                  icon: Icon(switch (preset) {
                    DevicePreset.smartphone => Icons.smartphone,
                    DevicePreset.android => Icons.phone_android,
                    DevicePreset.tablet => Icons.tablet_mac,
                  }, size: 16),
                ),
            ],
            selected: {device},
            onSelectionChanged: (selection) => onChangeDevice(selection.single),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const Spacer(),
          Text(
            '${device.width.toInt()} × ${device.height.toInt()}',
            style: TextStyle(
              fontSize: AppTypography.md,
              color: colors.inkMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          IconButton(
            tooltip: 'Diminuir zoom',
            iconSize: 18,
            icon: const Icon(Icons.zoom_out),
            onPressed: () => onChangeZoom(zoom - 0.1),
          ),
          Text(
            '${(zoom * 100).round()}%',
            style: const TextStyle(fontSize: AppTypography.md),
          ),
          IconButton(
            tooltip: 'Aumentar zoom',
            iconSize: 18,
            icon: const Icon(Icons.zoom_in),
            onPressed: () => onChangeZoom(zoom + 0.1),
          ),
        ],
      ),
    );
  }
}
