import 'package:equatable/equatable.dart';

import 'field_kind.dart';

class PropField extends Equatable {
  const PropField({
    required this.key,
    required this.kind,
    required this.label,
    required this.group,
    this.enumValues = const [],
    this.defaultValue,
    this.isRequired = false,
  });

  final String key;

  final FieldKind kind;

  final String label;

  final String group;

  final List<String> enumValues;

  /// O renderer aplica este mesmo default na ausência da prop.
  final Object? defaultValue;

  final bool isRequired;

  @override
  List<Object?> get props => [
    key,
    kind,
    label,
    group,
    enumValues,
    defaultValue,
    isRequired,
  ];
}

abstract final class FieldGroups {
  static const layout = 'Layout';
  static const size = 'Tamanho';
  static const spacing = 'Espaçamento';
  static const style = 'Estilo';
  static const content = 'Conteúdo';
}
