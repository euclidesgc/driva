import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/new_tab_launcher.dart';
import 'package:flutter/material.dart';

class DemoApkDownloadBlock extends StatelessWidget {
  const DemoApkDownloadBlock({
    required this.url,
    this.launcher = const NewTabLauncher(),
    super.key,
  });

  final String url;
  final NewTabLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final textStyle = TextStyle(
      fontSize: AppTypography.sm,
      color: colors.inkSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Este é um app de demonstração com um conteúdo fixo — não '
            'mostra o que você está editando agora.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'No iPhone, use o preview instalável acima.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'O Android vai pedir permissão para instalar de fonte '
            'desconhecida. Se já tiver uma versão instalada, desinstale '
            'antes de instalar esta.',
            style: textStyle,
          ),
          const SizedBox(height: AppSpacing.s12),
          Tooltip(
            message: 'Abre $url em nova aba',
            child: OutlinedButton.icon(
              onPressed: () => launcher.open(url),
              icon: const Icon(Icons.android),
              label: const Text('Baixar APK de teste'),
            ),
          ),
        ],
      ),
    );
  }
}
