import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// O gatilho só nasce com a ação escolhida: o kernel recusa passo sem ação,
/// então fechar o seletor não grava nada.
class AddTriggerButton extends StatelessWidget {
  const AddTriggerButton({
    required this.available,
    required this.onAdd,
    super.key,
  });

  final List<EventTrigger> available;

  final void Function(EventTrigger trigger, ActionDescriptor action) onAdd;

  Future<void> _chooseAction(BuildContext context, EventTrigger trigger) async {
    final action = await ActionPickerDialog.show(context);
    if (action != null) onAdd(trigger, action);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final isEnabled = available.isNotEmpty;
    final color = isEnabled
        ? Theme.of(context).colorScheme.primary
        : colors.inkMuted;
    return PopupMenuButton<EventTrigger>(
      enabled: isEnabled,
      tooltip: isEnabled
          ? 'Adicionar gatilho'
          : 'Todos os gatilhos já estão configurados',
      onSelected: (trigger) => _chooseAction(context, trigger),
      itemBuilder: (_) => [
        for (final trigger in available)
          PopupMenuItem(value: trigger, child: Text(trigger.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Row(
          children: [
            Icon(Icons.add, size: AppIconSizes.s16, color: color),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                'Adicionar gatilho',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.base,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
