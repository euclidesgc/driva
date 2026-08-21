import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// "Publicado" / "Despublicado" / "Rascunho" — ícone + texto, nunca só cor. O
/// tooltip carrega a nuance que o rótulo curto omite (publicado com alterações
/// pendentes de republicar, ou despublicado com histórico ainda guardado).
class PublicationBadge extends StatelessWidget {
  const PublicationBadge({
    required this.publishedAt,
    required this.hasUnpublishedChanges,
    this.latestVersion,
    super.key,
  });

  final DateTime? publishedAt;
  final bool hasUnpublishedChanges;
  final int? latestVersion;

  bool get _isPublished => publishedAt != null;
  bool get _everPublished => latestVersion != null;

  String get _tooltip => switch ((
    _isPublished,
    hasUnpublishedChanges,
    _everPublished,
  )) {
    (true, true, _) => 'Publicado, com alterações ainda não publicadas',
    (true, false, _) => 'Publicado — a versão publicada bate com o rascunho',
    (false, _, true) =>
      'Despublicado — o histórico de versões continua guardado',
    (false, _, false) => 'Nunca publicado',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final label = switch ((_isPublished, _everPublished)) {
      (true, _) => 'Publicado',
      (false, true) => 'Despublicado',
      (false, false) => 'Rascunho',
    };
    final icon = switch ((_isPublished, _everPublished)) {
      (true, _) => Icons.public,
      (false, true) => Icons.unpublished_outlined,
      (false, false) => Icons.edit_note_outlined,
    };
    final color = switch ((_isPublished, _everPublished)) {
      (true, _) => colors.success,
      (false, true) => colors.danger,
      (false, false) => colors.inkMuted,
    };

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
