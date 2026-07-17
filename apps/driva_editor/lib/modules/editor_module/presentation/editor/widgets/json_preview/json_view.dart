import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/theme/syntax_colors.dart';
import 'package:driva_editor/core/widgets/painters/painters.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/json_preview/line_gutter.dart';
import 'package:flutter/material.dart';

class JsonView extends StatelessWidget {
  const JsonView({required this.json, super.key});

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
    // Padding vertical no scroll externo: gutter e texto precisam alinhar 1:1.
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
