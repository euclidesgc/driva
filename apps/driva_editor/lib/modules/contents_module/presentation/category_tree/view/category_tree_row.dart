import 'package:flutter/material.dart';

import '../../../../../core/theme/editor_colors.dart';
import 'row_icon_button.dart';

/// A linha visual de uma categoria (ou do pseudo-nó "Todos os conteúdos"). Puro
/// desenho a partir dos dados/estado recebidos pelo construtor — o hover e o
/// alvo de drop são calculados pelo [CategoryRow] (stateful) e passados aqui.
class CategoryTreeRow extends StatelessWidget {
  const CategoryTreeRow({
    super.key,
    required this.label,
    required this.icon,
    required this.depth,
    required this.collapsed,
    required this.count,
    required this.selected,
    required this.isDropTarget,
    required this.hovered,
    required this.isAllContentsShortcut,
    required this.onSelect,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onHoverChanged,
  });

  final String label;
  final IconData icon;
  final int depth;
  final bool collapsed;
  final int? count;
  final bool selected;
  final bool isDropTarget;
  final bool hovered;
  final bool isAllContentsShortcut;
  final VoidCallback onSelect;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool> onHoverChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final theme = Theme.of(context);

    // A cor nunca é o único sinal de seleção/highlight: o nó ativo (ou o
    // alvo do drop) também ganha um contorno (accent) — não só a tinta de
    // fundo.
    final highlighted = selected || isDropTarget;
    final row = Container(
      margin: EdgeInsets.only(left: depth * 16.0, bottom: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primaryTint
            : (hovered ? colors.panelAlt : Colors.transparent),
        borderRadius: BorderRadius.circular(9),
        border: highlighted
            ? Border.all(color: theme.colorScheme.primary, width: 1)
            : null,
      ),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: onToggle != null
                ? Tooltip(
                    message: collapsed ? 'Expandir' : 'Recolher',
                    child: InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(
                        collapsed ? Icons.chevron_right : Icons.expand_more,
                        size: 16,
                        color: colors.inkMuted,
                      ),
                    ),
                  )
                : null,
          ),
          Icon(
            icon,
            size: 16,
            color: highlighted ? theme.colorScheme.primary : colors.inkMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: highlighted || isAllContentsShortcut
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: highlighted
                    ? theme.colorScheme.primary
                    : colors.inkPrimary,
              ),
            ),
          ),
          if (hovered && (onEdit != null || onDelete != null)) ...[
            if (onEdit != null)
              RowIconButton(
                tooltip: 'Editar categoria $label',
                icon: Icons.edit_outlined,
                onPressed: onEdit!,
              ),
            if (onDelete != null)
              RowIconButton(
                tooltip: 'Excluir categoria $label',
                icon: Icons.delete_outline,
                onPressed: onDelete!,
              ),
          ] else if (count != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        selected: selected,
        label: isAllContentsShortcut
            ? '$label, ver todos os conteúdos do projeto'
                  '${count != null ? ', $count conteúdos' : ''}'
            : (count != null ? '$label, $count conteúdos' : label),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(9),
          child: row,
        ),
      ),
    );
  }
}
