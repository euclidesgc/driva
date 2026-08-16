import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:flutter/material.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    required this.device,
    required this.effectiveScale,
    required this.fitToWindow,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onToggleFitToWindow,
    required this.onOpenPreview,
    super.key,
  });

  final DevicePreset device;

  /// Escala de fato aplicada ao mock — o `zoom` manual do cubit com o ajuste
  /// desligado, ou a saída de `fitScaleFor` com ele ligado (D9). É o que a
  /// barra mostra, para nunca exibir um percentual que a moldura desmente —
  /// e a base dos botões +/-, para o clique continuar do que está na tela.
  final double effectiveScale;
  final bool fitToWindow;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;
  final VoidCallback onToggleFitToWindow;

  /// Abre o diálogo com a URL/QR do preview no celular (D3, item 41). Quem
  /// monta este widget só o faz com `EditorReady` (`CanvasArea` carrega o
  /// canvas inteiro a partir daí), então `null` aqui é só o estado transitório
  /// antes disso — o botão some em vez de aparecer desabilitado sem explicar
  /// por quê, e nunca chega a existir um toque para ignorar em silêncio.
  final VoidCallback? onOpenPreview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final canZoomOut = !(fitToWindow && effectiveScale <= EditorCubit.minZoom);
    return Container(
      height: AppSizes.canvasToolbarHeight,
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
          Text(
            '${device.width.toInt()} × ${device.height.toInt()}',
            style: TextStyle(
              fontSize: AppTypography.md,
              color: colors.inkMuted,
            ),
          ),
          if (onOpenPreview != null) ...[
            const SizedBox(width: AppSpacing.s16),
            IconButton(
              tooltip: 'Ver no celular',
              iconSize: AppIconSizes.s18,
              icon: const Icon(Icons.smartphone),
              onPressed: onOpenPreview,
            ),
          ],
          const SizedBox(width: AppSpacing.s16),
          IconButton(
            tooltip: 'Ajustar à janela',
            iconSize: AppIconSizes.s18,
            isSelected: fitToWindow,
            icon: const Icon(Icons.fit_screen_outlined),
            selectedIcon: const Icon(Icons.fit_screen),
            onPressed: onToggleFitToWindow,
          ),
          const SizedBox(width: AppSpacing.s16),
          IconButton(
            tooltip: canZoomOut
                ? 'Diminuir zoom'
                : 'Diminuir zoom (já no piso do ajuste automático)',
            iconSize: AppIconSizes.s18,
            icon: const Icon(Icons.zoom_out),
            onPressed: canZoomOut
                ? () => onChangeZoom(effectiveScale - 0.1)
                : null,
          ),
          Text(
            '${(effectiveScale * 100).round()}%',
            style: const TextStyle(fontSize: AppTypography.md),
          ),
          IconButton(
            tooltip: 'Aumentar zoom',
            iconSize: AppIconSizes.s18,
            icon: const Icon(Icons.zoom_in),
            onPressed: () => onChangeZoom(effectiveScale + 0.1),
          ),
        ],
      ),
    );
  }
}
