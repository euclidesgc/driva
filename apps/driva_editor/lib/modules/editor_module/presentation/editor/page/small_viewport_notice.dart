import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/editor_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SmallViewportNotice extends StatelessWidget {
  const SmallViewportNotice({
    required this.projectId,
    required this.contentId,
    super.key,
  });

  final String projectId;

  final String contentId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.desktop_windows_outlined,
                size: AppIconSizes.s40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'A tela está pequena demais para o construtor',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'A paleta de widgets, a árvore e o inspector precisam de '
                'espaço lado a lado para funcionar — eles não cabem numa '
                'janela deste tamanho. Veja o conteúdo como ele está ou '
                'volte para a lista.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Wrap(
                spacing: AppSpacing.s12,
                runSpacing: AppSpacing.s12,
                alignment: WrapAlignment.center,
                children: [
                  // `contentId` vazio só ocorre em quem monta `EditorPage`
                  // fora do `pageBuilder` (D19) — sem ele, `goNamed` casaria
                  // com `/preview/:projectId` e cairia no 404 do router em
                  // vez do guard de `PreviewPage`. Esconder é mais seguro do
                  // que navegar para um link que não casa com a rota.
                  if (contentId.isNotEmpty)
                    Semantics(
                      button: true,
                      label:
                          'Ver conteúdo — abre a visualização deste '
                          'conteúdo, sem os painéis de edição',
                      child: Tooltip(
                        message: 'Abre a visualização do conteúdo',
                        child: ElevatedButton(
                          onPressed: () => context.goNamed(
                            EditorRoutes.previewName,
                            pathParameters: {
                              'projectId': projectId,
                              'id': contentId,
                            },
                          ),
                          child: const Text('Ver conteúdo'),
                        ),
                      ),
                    ),
                  Semantics(
                    button: true,
                    label:
                        'Voltar aos conteúdos — volta para a lista de '
                        'conteúdos do projeto',
                    child: Tooltip(
                      message: 'Volta para a lista de conteúdos',
                      child: OutlinedButton(
                        onPressed: () => context.goNamed(
                          ContentsRoutes.projectDetailName,
                          pathParameters: {'id': projectId},
                        ),
                        child: const Text('Voltar aos conteúdos'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
