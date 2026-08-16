import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// A instalação é o que ensina o sistema a capturar o `scope` do preview
/// (D31) — o segundo manifest existir não basta. Quem abre o link direto no
/// navegador continua com a barra de endereços, e sem esta dica não tem como
/// saber que o caminho limpo depende de um passo manual dele.
///
/// O texto nomeia o Android de propósito: no iOS o Safari nunca entrega um
/// link para o app instalado, então lá a tela cheia só vale ao abrir pelo
/// ícone. Uma dica que prometesse o mesmo nos dois mentiria no iPhone.
class PreviewInstallHint extends StatelessWidget {
  const PreviewInstallHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.r8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.add_to_home_screen_rounded,
            size: AppIconSizes.s18,
            color: colors.inkSecondary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Instale o preview no celular. ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                        'Com a página aberta, use "Adicionar à tela inicial" '
                        'no menu do navegador. O preview passa a abrir em '
                        'tela cheia, sem a barra de endereços — no Android, '
                        'inclusive ao tocar no link.',
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: colors.inkSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
