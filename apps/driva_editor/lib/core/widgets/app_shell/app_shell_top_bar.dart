import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_status_indicator.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar_actions.dart';
import 'package:driva_editor/core/widgets/branding/branding.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellTopBar extends StatelessWidget {
  const AppShellTopBar({
    required this.homeRouteName,
    required this.themeButton,
    super.key,
  });

  final String homeRouteName;
  final Widget themeButton;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final controller = AppShellScope.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // O colapso é decidido **contando as ações que a barra tem**, e não
        // comparando a janela contra uma constante gravada à mão. A constante
        // precisou ser recalibrada duas vezes em dois dias, e errar a conta
        // estoura o layout ou colapsa cedo demais, sem nada reprovar. Ação
        // nova, rótulo traduzido ou tipografia diferente entram nesta conta
        // sozinhos.
        final needed =
            AppSizes.topBarChromeWidth +
            estimatedActionsWidth(
              controller.actions,
              Theme.of(context).textTheme.labelLarge,
            ) +
            kActionsWidthSafety;
        final isCompact = constraints.maxWidth < needed;
        return Material(
          color: colors.panel,
          child: Container(
            height: AppSizes.topBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                AppWordmark(
                  compact: isCompact,
                  onTap: () => context.goNamed(homeRouteName),
                ),
                // O status precede o `Spacer` porque seu texto muda de
                // largura com o estado de publicação ("Publicado (v3)" ×
                // "Alterações não publicadas (publicada: v3)"). Depois do
                // `Spacer`, cada troca deslocava horizontalmente todos os
                // botões. `Expanded` (fit tight) é obrigatório aqui — um
                // `Flexible` (fit loose) encolhe até o conteúdo, então a
                // dupla de flexíveis passa a somar larguras diferentes a
                // cada rótulo e o deslocamento reaparece. Com `Expanded`,
                // o status sempre ocupa sua fatia cheia do espaço livre
                // (texto alinhado à esquerda, sobra em branco à direita) e
                // a faixa de ações fica ancorada à direita, em posição
                // estável.
                if (controller.status case final status?) ...[
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(child: AppShellStatusIndicator(status: status)),
                ],
                const Spacer(),
                AppShellTopBarActions(
                  actions: controller.actions,
                  compact: isCompact,
                ),
                const SizedBox(width: AppSpacing.s8),
                themeButton,
              ],
            ),
          ),
        );
      },
    );
  }
}
