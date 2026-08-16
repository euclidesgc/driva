import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/new_tab_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// O diálogo que sai do laptop (D3): QR code **e** link copiável, os dois —
/// pedido explícito do humano. O diálogo é do editor (desktop); a URL leva à
/// vista de preview, sem chrome, no celular.
class PreviewShareDialog extends StatelessWidget {
  const PreviewShareDialog({required this.url, super.key});

  final String url;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return AlertDialog(
      title: const Text('Ver no celular'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aponte a câmera do celular para o QR code, ou copie o link.',
          ),
          const SizedBox(height: AppSpacing.s16),
          Center(
            child: QrImageView(
              data: url,
              size: AppSpacing.s180,
              backgroundColor: colors.panel,
              semanticsLabel: 'QR code para abrir o preview no celular',
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: colors.inkPrimary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: colors.inkPrimary,
              ),
              // Sem isto o `qr_flutter` degrada para um `Container()` vazio —
              // um quadrado em branco sem sinal nenhum de que algo falhou. O
              // link logo abaixo continua funcionando; só falta dizer isso.
              errorStateBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Text(
                    'Não foi possível gerar o QR — use o link abaixo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.sm,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s10,
            ),
            decoration: BoxDecoration(
              color: colors.panelAlt,
              borderRadius: BorderRadius.circular(AppRadii.r8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: AppTypography.sm,
                      color: colors.inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Tooltip(
                  message: 'Copiar link',
                  child: Semantics(
                    button: true,
                    label: 'Copiar link do preview',
                    child: InkWell(
                      onTap: () => _copy(context),
                      borderRadius: BorderRadius.circular(AppRadii.r6),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.s4),
                        child: Icon(
                          Icons.copy_rounded,
                          size: AppIconSizes.s18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => const NewTabLauncher().open(url),
          child: const Text('Abrir em nova aba'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
