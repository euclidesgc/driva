import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupportId extends StatelessWidget {
  const SupportId({required this.id, super.key});

  final String id;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID copiado'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: colors.inkMuted,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Tooltip(
            message: 'ID de suporte — use ao reportar um problema.',
            child: Semantics(
              label: 'ID de suporte: $id',
              child: Text(
                'ID: $id',
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Tooltip(
          message: 'Copiar ID',
          child: Semantics(
            button: true,
            label: 'Copiar ID de suporte',
            child: InkWell(
              onTap: () => _copy(context),
              borderRadius: BorderRadius.circular(AppRadii.r6),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.s3),
                child: Icon(Icons.copy_rounded, size: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
