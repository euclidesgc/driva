import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/editor_colors.dart';

class SupportId extends StatelessWidget {
  const SupportId({super.key, required this.id});

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
        const SizedBox(width: 2),
        Tooltip(
          message: 'Copiar ID',
          child: Semantics(
            button: true,
            label: 'Copiar ID de suporte',
            child: InkWell(
              onTap: () => _copy(context),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.copy_rounded, size: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
