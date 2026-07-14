import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../../../../../../core/theme/syntax_colors.dart';
import '../../../../../../core/widgets/painters/painters.dart';
import 'line_gutter.dart';

class JsonView extends StatelessWidget {
  const JsonView({super.key, required this.json});

  final String json;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontFamily: 'monospace',
      fontSize: AppTypography.md,
      height: 1.5,
    );
    final colors = Theme.of(context).extension<EditorColors>()!;
    final syntax = Theme.of(context).extension<SyntaxColors>()!;
    final lineCount = '\n'.allMatches(json).length + 1;
    // Rolagem vertical envolve gutter + texto (sobem juntos); só o texto rola
    // na horizontal. O padding vertical fica no scroll externo para o gutter
    // e o texto começarem na mesma linha (mesmo `height` → alinhados 1:1).
    return ColoredBox(
      color: colors.panel,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LineGutter(count: lineCount, style: base, colors: colors),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: SelectableText.rich(
                    TextSpan(
                      children: JsonHighlighter.highlight(
                        json,
                        base: base,
                        colors: syntax,
                      ),
                    ),
                    style: base,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
