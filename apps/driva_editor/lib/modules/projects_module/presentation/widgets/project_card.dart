import 'package:flutter/material.dart';

import '../../../../core/theme/editor_colors.dart';
import '../../domain/entities/entities.dart';
import 'project_cover.dart';
import 'project_footer_counts.dart';

/// Card de projeto compartilhado entre a lista ativa e os arquivados — mesma
/// casca (capa, título, descrição, contadores) para garantir paridade visual.
///
/// Os pontos de divergência entram por slots/callbacks, não por duplicação:
/// - [onTap]: liga o comportamento interativo (hover-lift + abrir ao clicar);
///   nulo deixa o card estático (arquivados).
/// - [onEdit]: mostra o botão de editar na capa (só na lista ativa).
/// - [attenuated]: esmaece o card (sinal de arquivado, além do badge textual).
/// - [coverOverlay]: sobreposto à capa (ex.: badge "Arquivado").
/// - [actions]: entra abaixo dos contadores (ex.: Restaurar/excluir).
class ProjectCard extends StatefulWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onEdit,
    this.attenuated = false,
    this.coverOverlay,
    this.actions,
  });

  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool attenuated;
  final Widget? coverOverlay;
  final Widget? actions;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final project = widget.project;
    final interactive = widget.onTap != null;

    Widget cover = ProjectCover(
      project: project,
      hovered: _hovered,
      onEdit: widget.onEdit,
    );
    if (widget.coverOverlay != null) {
      cover = Stack(children: [cover, widget.coverOverlay!]);
    }

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      transform: _hovered
          ? (Matrix4.identity()..translateByDouble(0.0, -3.0, 0.0, 1.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cover,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 38,
                      child: Text(
                        project.description?.isNotEmpty == true
                            ? project.description!
                            : 'Sem descrição.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.inkSecondary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: colors.border)),
                      ),
                      child: ProjectFooterCounts(project: project),
                    ),
                    if (widget.actions != null) ...[
                      const SizedBox(height: 14),
                      widget.actions!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (interactive) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: card,
      );
    }
    if (widget.attenuated) {
      card = Opacity(opacity: 0.72, child: card);
    }
    return card;
  }
}
