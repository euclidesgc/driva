import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';

/// Nome da categoria do conteúdo — ícone de pasta + texto, para que a
/// informação não dependa só da cor. Omite a linha inteira quando [name]
/// não resolveu (árvore ainda carregando ou `categoryId` fora do mapa).
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({super.key, required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Tooltip(
      message: 'Categoria',
      child: Semantics(
        label: 'Categoria: $name',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_outlined, size: 13, color: colors.inkMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
