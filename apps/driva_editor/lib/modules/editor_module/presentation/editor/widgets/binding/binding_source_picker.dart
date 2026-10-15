import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding_source_tile.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// A lista das fontes de variável disponíveis num contexto, com busca.
///
/// Não conhece o inspector nem o cubit: recebe o tipo esperado, o contexto e
/// as fontes pelo construtor. Filtra só pelo contexto e pela busca; a fonte
/// de tipo incompatível aparece desabilitada, não some.
class BindingSourcePicker extends StatefulWidget {
  const BindingSourcePicker({
    required this.expectedType,
    required this.bindingContext,
    required this.selectedSourceId,
    required this.onSelected,
    this.sources = bindingSourceCatalog,
    super.key,
  });

  final PropValueType expectedType;
  final BindingContext bindingContext;
  final String? selectedSourceId;
  final ValueChanged<BindingSource> onSelected;
  final List<BindingSource> sources;

  @override
  State<BindingSourcePicker> createState() => _BindingSourcePickerState();
}

class _BindingSourcePickerState extends State<BindingSourcePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final source in widget.sources)
        if (source.isAvailableIn(widget.bindingContext) &&
            source.label.toLowerCase().contains(query))
          source,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          hintText: 'Buscar fonte…',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.s8),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Text(
              'Nenhuma fonte encontrada.',
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: colors.inkMuted,
              ),
            ),
          )
        else
          for (final source in visible)
            BindingSourceTile(
              key: ValueKey(source.id),
              source: source,
              isEnabled: source.feeds(widget.expectedType),
              isSelected: source.id == widget.selectedSourceId,
              onTap: () => widget.onSelected(source),
            ),
      ],
    );
  }
}
