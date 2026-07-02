import 'package:equatable/equatable.dart';

import 'field_kind.dart';

/// Descreve um campo editável de um primitivo. O Inspector do editor deriva
/// o formulário 100% desta descrição — nada de campo hardcoded por tipo.
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

  /// Chave da prop no JSON do spec (`props[key]`).
  final String key;

  final FieldKind kind;

  /// Rótulo exibido no Inspector (pt-BR).
  final String label;

  /// Seção do Inspector (rótulos centralizados em `FieldGroups`).
  final String group;

  /// Opções quando [kind] é [FieldKind.enumeration].
  final List<String> enumValues;

  /// Pré-preenchido ao adicionar o componente, para o usuário ver o que está
  /// de fato configurado. O renderer aplica o mesmo default na ausência.
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

/// Rótulos dos grupos (seções do Inspector), centralizados para consistência.
/// O editor renderiza um cabeçalho por grupo, na ordem de primeira aparição.
abstract final class FieldGroups {
  static const layout = 'Layout';
  static const size = 'Tamanho';
  static const spacing = 'Espaçamento';
  static const style = 'Estilo';
  static const content = 'Conteúdo';
}
