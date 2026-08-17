import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/editor_notice_message.dart';
import 'package:flutter/material.dart';

/// Recado da barra de status. Falha de publicar/restaurar ganha ícone e cor
/// de erro — cor nunca é o único sinal (acessibilidade); as demais dicas de
/// arraste seguem neutras, como já eram.
class StatusBarNotice extends StatelessWidget {
  const StatusBarNotice({required this.notice, super.key});

  final EditorNotice notice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final isFailure = EditorNoticeMessage.isFailure(notice.kind);
    final tone = isFailure ? colors.danger : colors.inkMuted;
    final message = EditorNoticeMessage.of(notice);

    final row = Row(
      children: [
        if (isFailure) ...[
          Icon(Icons.error_outline, size: 14, color: tone),
          const SizedBox(width: AppSpacing.s6),
        ],
        Expanded(
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: AppTypography.sm, color: tone),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s12),
      child: isFailure
          ? Semantics(liveRegion: true, label: 'Erro: $message', child: row)
          : row,
    );
  }
}
