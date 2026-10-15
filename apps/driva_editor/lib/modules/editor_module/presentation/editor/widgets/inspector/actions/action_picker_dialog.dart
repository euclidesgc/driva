import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class ActionPickerDialog extends StatefulWidget {
  const ActionPickerDialog({this.actions, super.key});

  /// `null` = as ações disponíveis numa página.
  final List<ActionDescriptor>? actions;

  /// Completa com `null` quando o diálogo fecha sem escolha.
  static Future<ActionDescriptor?> show(
    BuildContext context, {
    List<ActionDescriptor>? actions,
  }) => showDialog<ActionDescriptor>(
    context: context,
    builder: (_) => ActionPickerDialog(actions: actions),
  );

  @override
  State<ActionPickerDialog> createState() => _ActionPickerDialogState();
}

class _ActionPickerDialogState extends State<ActionPickerDialog> {
  late final List<ActionDescriptor> _actions =
      widget.actions ?? actionsFor(BindingContext.page);

  String _query = '';

  bool _matches(ActionDescriptor action) =>
      action.label.toLowerCase().contains(_query) ||
      action.type.toLowerCase().contains(_query);

  void _pick(ActionDescriptor action) => Navigator.of(context).pop(action);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final found = [
      for (final action in _actions)
        if (_matches(action)) action,
    ];
    final categoryStyle = TextStyle(
      fontSize: AppTypography.sm,
      fontWeight: FontWeight.w600,
      color: colors.inkSecondary,
    );
    return Dialog(
      child: SizedBox(
        width: AppSizes.formDialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Escolher ação',
                  style: TextStyle(
                    fontSize: AppTypography.base,
                    fontWeight: FontWeight.w600,
                    color: colors.inkPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              SearchField(
                hintText: 'Buscar ação…',
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.s8),
              if (found.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s16,
                  ),
                  child: Text(
                    'Nenhuma ação encontrada.',
                    style: TextStyle(color: colors.inkMuted),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (_query.isNotEmpty)
                        for (final action in found)
                          ActionPickerTile(
                            action: action,
                            showCategory: true,
                            onTap: () => _pick(action),
                          )
                      else
                        for (final category in ActionCategories.inPickerOrder)
                          if (found.any((a) => a.category == category)) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.s8,
                                bottom: AppSpacing.s4,
                              ),
                              child: Semantics(
                                header: true,
                                child: Text(category, style: categoryStyle),
                              ),
                            ),
                            for (final action in found)
                              if (action.category == category)
                                ActionPickerTile(
                                  action: action,
                                  onTap: () => _pick(action),
                                ),
                          ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
