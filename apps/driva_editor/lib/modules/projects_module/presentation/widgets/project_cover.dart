import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/cover_gradients.dart';
import '../../domain/entities/entities.dart';
import 'gradient_texture.dart';

/// Capa do card de projeto: gradiente estável por id (ou imagem, quando
/// houver `imageUrl`) + avatar com a inicial do título. Compartilhada entre
/// o card ativo (`project_list_page.dart`) e o arquivado
/// (`archived_projects_page.dart`) para manter paridade visual.
///
/// O botão de editar só aparece quando [onEdit] é informado — a lista de
/// arquivados não oferece edição (o projeto precisa ser restaurado antes).
class ProjectCover extends StatelessWidget {
  const ProjectCover({
    super.key,
    required this.project,
    this.hovered = false,
    this.onEdit,
  });

  final Project project;
  final bool hovered;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final gradient = AppCoverGradients.forSeed(project.id);
    final initial = project.title.trim().isNotEmpty
        ? project.title.trim()[0].toUpperCase()
        : '?';

    return SizedBox(
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (project.imageUrl != null && project.imageUrl!.isNotEmpty)
            Image.network(
              project.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => GradientTexture(gradient: gradient),
            )
          else
            GradientTexture(gradient: gradient),
          Positioned(
            left: 16,
            bottom: 12,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.r11),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTypography.xl,
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Positioned(
              top: 12,
              right: 12,
              child: Tooltip(
                message: 'Editar projeto',
                child: Semantics(
                  button: true,
                  label: 'Editar projeto ${project.title}',
                  child: Material(
                    color: Colors.black.withValues(alpha: hovered ? 0.5 : 0.32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.r9),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.r9),
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.s8),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
