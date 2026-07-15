import 'package:flutter/material.dart';

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
    final gradient = _gradientFor(project.id);
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
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
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
                      borderRadius: BorderRadius.circular(9),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
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

  List<Color> _gradientFor(String seed) {
    // Paleta fixa de gradientes (o protótipo alterna laranja/violeta); a
    // escolha por hash do id mantém o card com a mesma cor entre reloads.
    const palettes = [
      [Color(0xFFE07B39), Color(0xFFD96E2B)],
      [Color(0xFF7A5CF0), Color(0xFF5B3FD1)],
      [Color(0xFF2FA88E), Color(0xFF1F8A73)],
      [Color(0xFFD1476B), Color(0xFFB13457)],
    ];
    final index =
        seed.codeUnits.fold<int>(0, (sum, c) => sum + c) % palettes.length;
    return palettes[index];
  }
}
