import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';

/// Rodapé de "carregando mais" do scroll infinito (pílula com spinner + texto;
/// o texto garante que a informação não dependa só do movimento).
class LoadingMoreFooter extends StatelessWidget {
  const LoadingMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Carregando mais conteúdos',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Carregando mais…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
