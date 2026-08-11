import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/catalog/field_kind.dart';
import 'package:sdui_core/src/catalog/prop_option.dart';

class PropField extends Equatable {
  const PropField({
    required this.key,
    required this.kind,
    required this.label,
    required this.group,
    this.options = const [],
    this.min,
    this.max,
    this.step,
    this.helpText,
    this.defaultValue,
    this.isRequired = false,
    this.isAdvanced = false,
    this.isBindable = true,
  });

  final String key;

  final FieldKind kind;

  final String label;

  final String group;

  final List<PropOption> options;

  final num? min;

  final num? max;

  final num? step;

  final String? helpText;

  /// O renderer aplica este mesmo default na ausência da prop.
  final Object? defaultValue;

  final bool isRequired;

  /// Fica atrás do disclosure "Avançado" da seção.
  final bool isAdvanced;

  /// Aceita `{{binding}}` no lugar de um valor fixo.
  final bool isBindable;

  List<String> get enumValues => [for (final option in options) option.value];

  /// Com faixa conhecida o editor numérico ganha slider; sem ela, só o campo.
  bool get hasRange => min != null && max != null;

  @override
  List<Object?> get props => [
    key,
    kind,
    label,
    group,
    options,
    min,
    max,
    step,
    helpText,
    defaultValue,
    isRequired,
    isAdvanced,
    isBindable,
  ];
}

abstract final class FieldGroups {
  static const layout = 'Layout';
  static const size = 'Tamanho';
  static const spacing = 'Espaçamento';
  static const style = 'Estilo';
  static const content = 'Conteúdo';
}
