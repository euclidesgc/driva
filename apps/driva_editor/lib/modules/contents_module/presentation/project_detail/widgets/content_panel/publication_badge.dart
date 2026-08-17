import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// "No ar" / "Rascunho" — ícone + texto, nunca só cor (item 24). O tooltip
/// carrega a nuance que o rótulo curto omite (publicado com alterações
/// pendentes de republicar).
class PublicationBadge extends StatelessWidget {
  const PublicationBadge({
    required this.publishedAt,
    required this.hasUnpublishedChanges,
    super.key,
  });

  final DateTime? publishedAt;
  final bool hasUnpublishedChanges;

  bool get _isPublished => publishedAt != null;

  String get _tooltip => switch ((_isPublished, hasUnpublishedChanges)) {
    (true, true) => 'No ar, com alterações ainda não publicadas',
    (true, false) => 'No ar — o que está publicado bate com o rascunho',
    (false, _) => 'Nunca publicado',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final label = _isPublished ? 'No ar' : 'Rascunho';
    final icon = _isPublished ? Icons.public : Icons.edit_note_outlined;
    final color = _isPublished ? colors.success : colors.inkMuted;

    return Tooltip(
      message: _tooltip,
      child: Semantics(
        label: '$label: $_tooltip',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSizes.s13, color: color),
            const SizedBox(width: AppSpacing.s4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
