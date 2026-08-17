import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_toolbar_row.dart';
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
    required this.isFullscreen,
    required this.onToggleFullscreen,
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

  /// Controle primário do modo tela cheia (F7/D16): botão sempre visível na
  /// barra do canvas — o `Esc` é só o atalho secundário.
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    // A barra mede a largura que sobrou para ela, não a da janela: o painel
    // central encolhe quando os laterais abrem, então janela larga não
    // garante barra larga.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dense = width < AppSizes.canvasToolbarDenseFitWidth;
        return Container(
          height: AppSizes.canvasToolbarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: dense ? AppSpacing.s8 : AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: CanvasToolbarRow(
            device: device,
            effectiveScale: effectiveScale,
            fitToWindow: fitToWindow,
            showDimensions: width >= AppSizes.canvasToolbarDimensionsFitWidth,
            collapseSecondary: width < AppSizes.canvasToolbarActionsFitWidth,
            dense: dense,
            onChangeDevice: onChangeDevice,
            onChangeZoom: onChangeZoom,
            onToggleFitToWindow: onToggleFitToWindow,
            onOpenPreview: onOpenPreview,
            isFullscreen: isFullscreen,
            onToggleFullscreen: onToggleFullscreen,
          ),
        );
      },
    );
  }
}
