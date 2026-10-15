import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/layout/dialog_content_width.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding_source_picker.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding_value_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/prop_value_type_label.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// "Ligar a variável": escolhe a fonte e configura o binding de uma prop.
///
/// Devolve o [BoundPropValue] por `Navigator.pop`, ou `null` se a pessoa
/// cancelar. Não conhece o inspector nem o cubit: recebe o [field] (tipo,
/// obrigatoriedade e o editor tipado do padrão e da prévia), o contexto e as
/// fontes pelo construtor, e quem abre decide o que fazer com o resultado.
class BindingDialog extends StatefulWidget {
  const BindingDialog({
    required this.field,
    required this.bindingContext,
    this.sources = bindingSourceCatalog,
    this.initial,
    this.initialFallback,
    super.key,
  });

  final PropField field;
  final BindingContext bindingContext;
  final List<BindingSource> sources;

  /// O binding atual, para reabrir o diálogo preenchido.
  final BoundPropValue? initial;

  /// O valor fixo atual da prop, que vira o padrão inicial.
  final Object? initialFallback;

  @override
  State<BindingDialog> createState() => _BindingDialogState();
}

class _BindingDialogState extends State<BindingDialog> {
  late String? _sourceId = widget.initial?.source;
  late final TextEditingController _path = TextEditingController(
    text: widget.initial?.path ?? '',
  );
  late Object? _fallback = widget.initial?.fallback ?? widget.initialFallback;
  late Object? _preview = widget.initial?.preview;
  String? _pathError;
  String? _fallbackError;

  bool get _isLegacy => _sourceId == BindingSourceIds.legacy;

  /// O `StringEditor` devolve `''` em campo obrigatório: vazio também é
  /// "sem valor".
  static bool _isAbsent(Object? value) =>
      value == null || (value is String && value.trim().isEmpty);

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  void _select(BindingSource source) => setState(() {
    _sourceId = source.id;
    _pathError = null;
    _fallbackError = null;
  });

  void _confirm() {
    final source = _sourceId;
    if (source == null) return;
    final path = _path.text.trim();
    final pathError = path.isNotEmpty
        ? null
        : _isLegacy
        ? 'Informe a expressão'
        : 'Informe o nome do parâmetro';
    final fallbackError =
        !_isLegacy && widget.field.isRequired && _isAbsent(_fallback)
        ? 'Informe um valor padrão'
        : null;
    if (pathError != null || fallbackError != null) {
      setState(() {
        _pathError = pathError;
        _fallbackError = fallbackError;
      });
      return;
    }
    Navigator.of(context).pop(
      _isLegacy
          ? BoundPropValue.legacy(path)
          : BoundPropValue(
              source: source,
              path: path,
              fallback: _isAbsent(_fallback) ? null : _fallback,
              preview: _isAbsent(_preview) ? null : _preview,
              literal: widget.initial?.literal,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final field = widget.field;
    final hasSource = _sourceId != null;

    return AlertDialog(
      title: Text('Ligar "${field.label}" a uma variável'),
      content: DialogContentWidth(
        maxWidth: AppSizes.wideFormDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tipo esperado: ${propValueTypeLabel(field.valueType)}',
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: colors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              BindingSourcePicker(
                expectedType: field.valueType,
                bindingContext: widget.bindingContext,
                sources: widget.sources,
                selectedSourceId: _sourceId,
                onSelected: _select,
              ),
              if (hasSource) ...[
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: _path,
                  style: const TextStyle(fontSize: AppTypography.base),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: _isLegacy ? 'Expressão' : 'Nome do parâmetro',
                    hintText: _isLegacy ? 'usuario.nome' : null,
                    prefixText: _isLegacy ? '{{' : null,
                    suffixText: _isLegacy ? '}}' : null,
                    errorText: _pathError,
                  ),
                  onChanged: (_) {
                    if (_pathError != null) setState(() => _pathError = null);
                  },
                ),
                // A fonte legada é só a expressão: não guarda padrão, prévia
                // nem literal. Os valores ficam no estado e voltam ao trocar
                // de novo para uma fonte tipada.
                if (!_isLegacy) ...[
                  const SizedBox(height: AppSpacing.s8),
                  BindingValueField(
                    key: const ValueKey('binding-fallback'),
                    label: 'Valor padrão',
                    field: field,
                    isRequired: field.isRequired,
                    value: _fallback,
                    errorText: _fallbackError,
                    onChanged: (value) => setState(() {
                      _fallback = value;
                      _fallbackError = null;
                    }),
                  ),
                  BindingValueField(
                    key: const ValueKey('binding-preview'),
                    label: 'Prévia no editor',
                    field: field,
                    value: _preview,
                    onChanged: (value) => setState(() => _preview = value),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: hasSource ? _confirm : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
