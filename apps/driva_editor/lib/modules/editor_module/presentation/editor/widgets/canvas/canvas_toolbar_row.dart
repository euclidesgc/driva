import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_actions_overflow_menu.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/return_to_published_button.dart';
import 'package:flutter/material.dart';

/// A faixa de controles do canvas numa largura já classificada pela
/// [CanvasToolbar]. **Nenhuma ação declarada some**: ou está visível, ou está
/// dentro do menu de overflow — o que sai de fato são só os dois rótulos
/// redundantes (a dimensão do preset, que o tooltip repete, e o percentual de
/// zoom, que a moldura do mock já mostra).
class CanvasToolbarRow extends StatelessWidget {
  const CanvasToolbarRow({
    required this.device,
    required this.effectiveScale,
    required this.fitToWindow,
    required this.showDimensions,
    required this.collapseSecondary,
    required this.dense,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onToggleFitToWindow,
    required this.onOpenPreview,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.isComparing = false,
    this.onReturnToPublished,
    super.key,
  });

  final DevicePreset device;
  final double effectiveScale;
  final bool fitToWindow;
  final bool showDimensions;
  final bool collapseSecondary;
  final bool dense;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;
  final VoidCallback onToggleFitToWindow;
  final VoidCallback? onOpenPreview;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final bool isComparing;
  final VoidCallback? onReturnToPublished;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final canZoomOut = !(fitToWindow && effectiveScale <= EditorCubit.minZoom);
    final gap = dense ? AppSpacing.s8 : AppSpacing.s16;
    final density = dense ? VisualDensity.compact : VisualDensity.standard;
    final fullscreenTooltip = isFullscreen
        ? 'Sair da tela cheia (Esc)'
        : 'Tela cheia';
    final collapsed = <AppBarAction>[
      if (onOpenPreview != null)
        AppBarAction.icon(
          icon: Icons.smartphone,
          tooltip: 'Ver no celular',
          onPressed: onOpenPreview,
        ),
      if (dense)
        AppBarAction.icon(
          icon: fitToWindow ? Icons.fit_screen : Icons.fit_screen_outlined,
          tooltip: 'Ajustar à janela',
          onPressed: onToggleFitToWindow,
        ),
      AppBarAction.icon(
        icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
        tooltip: fullscreenTooltip,
        onPressed: onToggleFullscreen,
      ),
    ];

    return Row(
      children: [
        if (isComparing) ...[
          if (onReturnToPublished != null) ...[
            ReturnToPublishedButton(
              onPressed: onReturnToPublished!,
              collapsed: collapseSecondary,
            ),
            SizedBox(width: gap),
          ],
        ],
        SegmentedButton<DevicePreset>(
          segments: [
            for (final preset in DevicePreset.values)
              ButtonSegment(
                value: preset,
                tooltip:
                    '${preset.label} '
                    '(${preset.width.toInt()}×${preset.height.toInt()})',
                icon: Icon(switch (preset) {
                  DevicePreset.smartphone => Icons.smartphone,
                  DevicePreset.android => Icons.phone_android,
                  DevicePreset.tablet => Icons.tablet_mac,
                }, size: AppIconSizes.s16),
              ),
          ],
          selected: {device},
          onSelectionChanged: (selection) => onChangeDevice(selection.single),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const Spacer(),
        if (showDimensions) ...[
          Text(
            '${device.width.toInt()} × ${device.height.toInt()}',
            style: TextStyle(
              fontSize: AppTypography.md,
              color: colors.inkMuted,
            ),
          ),
          SizedBox(width: gap),
        ],
        if (!collapseSecondary && onOpenPreview != null) ...[
          IconButton(
            tooltip: 'Ver no celular',
            iconSize: AppIconSizes.s18,
            icon: const Icon(Icons.smartphone),
            onPressed: onOpenPreview,
          ),
          SizedBox(width: gap),
        ],
        if (!dense) ...[
          IconButton(
            tooltip: 'Ajustar à janela',
            iconSize: AppIconSizes.s18,
            isSelected: fitToWindow,
            icon: const Icon(Icons.fit_screen_outlined),
            selectedIcon: const Icon(Icons.fit_screen),
            onPressed: onToggleFitToWindow,
          ),
          SizedBox(width: gap),
        ],
        IconButton(
          tooltip: canZoomOut
              ? 'Diminuir zoom'
              : 'Diminuir zoom (já no piso do ajuste automático)',
          iconSize: AppIconSizes.s18,
          visualDensity: density,
          icon: const Icon(Icons.zoom_out),
          onPressed: canZoomOut
              ? () => onChangeZoom(effectiveScale - 0.1)
              : null,
        ),
        if (!dense)
          Text(
            '${(effectiveScale * 100).round()}%',
            style: const TextStyle(fontSize: AppTypography.md),
          ),
        IconButton(
          tooltip: 'Aumentar zoom',
          iconSize: AppIconSizes.s18,
          visualDensity: density,
          icon: const Icon(Icons.zoom_in),
          onPressed: () => onChangeZoom(effectiveScale + 0.1),
        ),
        SizedBox(width: gap),
        if (collapseSecondary)
          AppShellActionsOverflowMenu(actions: collapsed)
        else
          IconButton(
            tooltip: fullscreenTooltip,
            iconSize: AppIconSizes.s18,
            isSelected: isFullscreen,
            icon: const Icon(Icons.fullscreen),
            selectedIcon: const Icon(Icons.fullscreen_exit),
            onPressed: onToggleFullscreen,
          ),
      ],
    );
  }
}
