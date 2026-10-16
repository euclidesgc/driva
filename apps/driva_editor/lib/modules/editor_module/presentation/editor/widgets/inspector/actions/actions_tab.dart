import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/editing_lock.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_steps.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/add_trigger_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/configured_trigger_card.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class ActionsTab extends StatelessWidget {
  const ActionsTab({
    required this.node,
    required this.descriptor,
    required this.onUpdateEvents,
    this.isReadOnly = false,
    super.key,
  });

  final SduiNode node;

  /// `null` = tipo sem descritor, que não oferece gatilho.
  final WidgetDescriptor? descriptor;

  final void Function(
    Map<String, List<Map<String, dynamic>>?> patch, {
    String? coalesceKey,
  })
  onUpdateEvents;

  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final descriptor = this.descriptor;
    if (descriptor == null || descriptor.triggers.isEmpty) {
      final colors = Theme.of(context).extension<EditorColors>()!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Text(
            'Este widget não tem gatilhos de ação.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.inkMuted,
              fontSize: AppTypography.base,
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        for (final trigger in configuredTriggers(node, descriptor))
          Padding(
            key: ValueKey(trigger.name),
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: EditingLock(
              locked: isReadOnly,
              child: ConfiguredTriggerCard(
                ownerKey: node.id,
                trigger: trigger,
                steps: stepsOf(node, trigger),
                onStepsChanged: (steps, {coalesceKey}) => onUpdateEvents({
                  trigger.name: steps,
                }, coalesceKey: coalesceKey),
                onRemove: () => onUpdateEvents({trigger.name: null}),
              ),
            ),
          ),
        EditingLock(
          locked: isReadOnly,
          child: AddTriggerButton(
            available: availableTriggers(node, descriptor),
            onAdd: (trigger, action) => onUpdateEvents({
              trigger.name: [initialStep(action)],
            }),
          ),
        ),
      ],
    );
  }
}
