import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../../../../../../core/widgets/painters/painters.dart';

class EmptyPreview extends StatelessWidget {
  const EmptyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = EditorColors.light;
    return Semantics(
      label: 'Conteúdo vazio. Adicione o primeiro widget.',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: CustomPaint(
            foregroundPainter: DashedBorderPainter(color: colors.border),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: 40,
                    color: colors.inkMuted,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Arraste um widget da paleta até aqui para começar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.inkSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
