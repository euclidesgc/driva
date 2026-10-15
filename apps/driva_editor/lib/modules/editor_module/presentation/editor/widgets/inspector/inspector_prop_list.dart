import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/editing_lock.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_group_summary.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_section.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// A busca é estado local: filtrar não pode reconstruir o cabeçalho do
/// Inspector nem o canvas.
class InspectorPropList extends StatefulWidget {
  const InspectorPropList({
    required this.ownerKey,
    required this.properties,
    required this.descriptor,
    required this.onUpdateProps,
    required this.onBindProp,
    required this.onUnbindProp,
    this.collapsedSections,
    this.mixedKeys = const {},
    this.isReadOnly = false,
    super.key,
  });

  /// Identidade de quem é dono das props (id do nó, ou `page`): entra nas
  /// `ValueKey` dos editores para trocar de dono não reaproveitar o campo.
  final String ownerKey;

  final Map<String, dynamic> properties;
  final WidgetDescriptor descriptor;
  final ValueChanged<Map<String, dynamic>> onUpdateProps;
  final void Function(String key, BoundPropValue binding) onBindProp;
  final ValueChanged<String> onUnbindProp;

  /// Rascunho congelado pelo modo de comparação: os campos ficam à vista,
  /// com o valor que têm, mas inertes — buscar, rolar e colapsar seção
  /// continuam, porque ler as propriedades é metade do que se faz comparando.
  final bool isReadOnly;

  /// Edição em lote: chaves cujo valor diverge entre os nós; mostram "Misto".
  final Set<String> mixedKeys;

  /// Chave é o rótulo do grupo (Q2/P3), lembrado globalmente entre nós — não
  /// por [descriptor]. `null` fora do `EditorLayoutScope` (ex. este widget
  /// testado isolado): mesma degradação do `LeftPanel`, a expansão fica só
  /// local, sem sobreviver a um remount.
  final ValueNotifier<Set<String>>? collapsedSections;

  @override
  State<InspectorPropList> createState() => _InspectorPropListState();
}

class _InspectorPropListState extends State<InspectorPropList> {
  String _query = '';

  final ValueNotifier<Set<String>> _fallbackCollapsedSections = ValueNotifier(
    {},
  );

  ValueNotifier<Set<String>> get _collapsedSections =>
      widget.collapsedSections ?? _fallbackCollapsedSections;

  void _toggleSection(String group, {required bool expanded}) {
    final collapsed = {..._collapsedSections.value};
    if (expanded) {
      collapsed.remove(group);
    } else {
      collapsed.add(group);
    }
    _collapsedSections.value = collapsed;
  }

  @override
  void dispose() {
    _fallbackCollapsedSections.dispose();
    super.dispose();
  }

  List<String> get _groupsInOrder {
    final groups = <String>[];
    for (final field in widget.descriptor.fields) {
      if (!groups.contains(field.group)) groups.add(field.group);
    }
    // Comum → tipo → partes; estável dentro de cada faixa.
    int rank(String group) {
      final section = widget.descriptor.fields
          .firstWhere((f) => f.group == group)
          .section;
      if (section == FieldSections.comum) return 0;
      if (section == FieldSections.tipo) return 1;
      return 2;
    }

    final indexed = [for (var i = 0; i < groups.length; i++) (i, groups[i])]
      ..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  List<PropField> _fieldsOf(String group) => [
    for (final field in widget.descriptor.fields)
      if (field.group == group &&
          _matches(field) &&
          FieldVisibility.isVisible(
            field,
            widget.properties,
            widget.descriptor,
          ))
        field,
  ];

  bool _matches(PropField field) =>
      _query.isEmpty ||
      field.label.toLowerCase().contains(_query) ||
      field.key.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final groups = [
      for (final group in _groupsInOrder)
        if (_fieldsOf(group).isNotEmpty) group,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s12,
            AppSpacing.s8,
            AppSpacing.s12,
            AppSpacing.s8,
          ),
          child: SearchField(
            hintText: 'Buscar propriedade…',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma propriedade encontrada.',
                    style: TextStyle(
                      color: colors.inkMuted,
                      fontSize: AppTypography.base,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                  children: [
                    for (final group in groups)
                      PropSection(
                        // Chave só do grupo (Q2/P3, não `descriptor.type`):
                        // sem ela, fechar uma seção "moveria" o estado para a
                        // que assumir o índice ao filtrar; com ela, dois nós
                        // diferentes com uma seção "Aparência" compartilham o
                        // colapso — intencional, não bug.
                        key: ValueKey(group),
                        label: group,
                        summary: PropGroupSummary.of(
                          _fieldsOf(group),
                          widget.properties,
                        ),
                        initiallyExpanded: !_collapsedSections.value.contains(
                          group,
                        ),
                        onExpandedChanged: (expanded) =>
                            _toggleSection(group, expanded: expanded),
                        children: [
                          for (final field in _fieldsOf(group)) ...[
                            if (widget.mixedKeys.contains(field.key))
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.s12,
                                ),
                                child: Text(
                                  'Misto',
                                  style: TextStyle(
                                    color: colors.inkMuted,
                                    fontSize: AppTypography.base,
                                  ),
                                ),
                              ),
                            EditingLock(
                              key: ValueKey('${widget.ownerKey}_${field.key}'),
                              locked: widget.isReadOnly,
                              child: PropFieldEditor(
                                field: field,
                                value: widget.properties[field.key],
                                onChanged: (value) =>
                                    widget.onUpdateProps({field.key: value}),
                                onBind: (binding) =>
                                    widget.onBindProp(field.key, binding),
                                onUnbind: () => widget.onUnbindProp(field.key),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
