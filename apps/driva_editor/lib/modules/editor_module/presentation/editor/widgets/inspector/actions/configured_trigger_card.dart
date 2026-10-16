import 'package:driva_editor/core/theme/action_icons.dart';
import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_picker_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_steps.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Edita só o primeiro passo do gatilho; os seguintes são do fluxo de ações
/// e atravessam intactos cada gravação.
class ConfiguredTriggerCard extends StatelessWidget {
  const ConfiguredTriggerCard({
    required this.ownerKey,
    required this.trigger,
    required this.steps,
    required this.onStepsChanged,
    required this.onRemove,
    super.key,
  });

  /// Entra na key dos campos: pelo valor, o campo seria recriado a cada tecla
  /// e o foco se perderia.
  final String ownerKey;

  final EventTrigger trigger;

  final ActionSteps steps;

  final void Function(ActionSteps steps, {String? coalesceKey}) onStepsChanged;

  final VoidCallback onRemove;

  Future<void> _swapAction(BuildContext context) async {
    final action = await ActionPickerDialog.show(context);
    if (action != null) onStepsChanged(withFirstStepAction(steps, action));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final first = steps.first;
    final type = actionTypeOf(first);
    final action = type == null ? null : actionFor(type);
    final params = paramsOf(first);
    final extraSteps = steps.length - 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadii.r6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    trigger.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.base,
                      fontWeight: FontWeight.w600,
                      color: colors.inkPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover gatilho ${trigger.label}',
                  iconSize: AppIconSizes.s16,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            Tooltip(
              message: 'Trocar ação',
              child: InkWell(
                onTap: () => _swapAction(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ActionIcons.resolve(action?.iconName) ??
                            Icons.bolt_outlined,
                        size: AppIconSizes.s16,
                        color: colors.inkSecondary,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          action?.label ?? type ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTypography.base,
                            color: colors.inkPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.swap_horiz,
                        size: AppIconSizes.s16,
                        color: colors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (extraSteps > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s4,
                ),
                child: Text(
                  extraSteps == 1 ? '+1 ação' : '+$extraSteps ações',
                  style: TextStyle(
                    fontSize: AppTypography.md,
                    color: colors.inkMuted,
                  ),
                ),
              ),
            for (final param in action?.params ?? const <PropField>[])
              PropFieldEditor(
                key: ValueKey('${ownerKey}_${trigger.name}_${param.key}'),
                field: param,
                value: params[param.key],
                onChanged: (value) => onStepsChanged(
                  withFirstStepParam(steps, param.key, value),
                  coalesceKey: 'events:$ownerKey:${trigger.name}:${param.key}',
                ),
                onBind: (binding) => onStepsChanged(
                  withFirstStepParam(
                    steps,
                    param.key,
                    boundParamValue(params[param.key], binding),
                  ),
                ),
                onUnbind: () => onStepsChanged(
                  withFirstStepParam(
                    steps,
                    param.key,
                    literalUnder(params[param.key]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
