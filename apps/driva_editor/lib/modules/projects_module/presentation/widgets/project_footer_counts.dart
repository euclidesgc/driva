import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:flutter/material.dart';

/// Contadores de "N categorias" / "N conteúdos" do rodapé do card — fiel ao
/// `.dc.html` (`p.catCount`/`p.contentCount`, ícone de pasta e de documento
/// lado a lado). Adendo P3 ao contrato de `GET /v1/projects` (registrar em
/// `docs/09-crud-projeto/variance_report.md`): os dois inteiros vêm sempre
/// presentes de `Project`. Compartilhado entre o card ativo e o arquivado.
class ProjectFooterCounts extends StatelessWidget {
  const ProjectFooterCounts({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: colors.inkMuted,
      fontSize: AppTypography.md,
    );
    return Semantics(
      label:
          '${project.categoryCount} '
          '${project.categoryCount == 1 ? 'categoria' : 'categorias'}, '
          '${project.contentCount} '
          '${project.contentCount == 1 ? 'conteúdo' : 'conteúdos'}',
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 14, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.s5),
          Text(
            '${project.categoryCount} '
            '${project.categoryCount == 1 ? 'categoria' : 'categorias'}',
            style: style,
          ),
          const SizedBox(width: AppSpacing.s14),
          Icon(Icons.description_outlined, size: 14, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.s5),
          Text(
            '${project.contentCount} '
            '${project.contentCount == 1 ? 'conteúdo' : 'conteúdos'}',
            style: style,
          ),
        ],
      ),
    );
  }
}
