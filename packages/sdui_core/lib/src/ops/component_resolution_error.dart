import 'package:equatable/equatable.dart';
import 'package:sdui_core/src/model/component_param_type.dart';

sealed class ComponentResolutionError extends Equatable {
  const ComponentResolutionError({required this.instanceId});

  final String instanceId;

  String get message;
}

final class ComponentNotFound extends ComponentResolutionError {
  const ComponentNotFound({
    required super.instanceId,
    required this.componentId,
  });

  final String componentId;

  @override
  String get message => 'Componente "$componentId" não encontrado';

  @override
  List<Object?> get props => [instanceId, componentId];
}

final class MissingRequiredArg extends ComponentResolutionError {
  const MissingRequiredArg({
    required super.instanceId,
    required this.componentName,
    required this.paramName,
  });

  final String componentName;
  final String paramName;

  @override
  String get message =>
      'Componente "$componentName": o parâmetro obrigatório "$paramName" '
      'não recebeu valor';

  @override
  List<Object?> get props => [instanceId, componentName, paramName];
}

final class ArgTypeMismatch extends ComponentResolutionError {
  const ArgTypeMismatch({
    required super.instanceId,
    required this.componentName,
    required this.paramName,
    required this.expected,
    required this.expectedList,
  });

  final String componentName;
  final String paramName;
  final ComponentParamType expected;
  final bool expectedList;

  String get _expectedLabel =>
      expectedList ? 'lista de ${expected.label}' : expected.label;

  @override
  String get message =>
      'Componente "$componentName": o valor do parâmetro "$paramName" '
      'não é do tipo esperado ($_expectedLabel)';

  @override
  List<Object?> get props => [
    instanceId,
    componentName,
    paramName,
    expected,
    expectedList,
  ];
}

final class ComponentCycle extends ComponentResolutionError {
  const ComponentCycle({required super.instanceId, required this.chain});

  final List<String> chain;

  @override
  String get message => 'Ciclo de componentes: ${chain.join(' → ')}';

  @override
  List<Object?> get props => [instanceId, chain];
}

final class ComponentDepthExceeded extends ComponentResolutionError {
  const ComponentDepthExceeded({
    required super.instanceId,
    required this.limit,
    required this.chain,
  });

  final int limit;
  final List<String> chain;

  @override
  String get message =>
      'Componentes aninhados além do limite de $limit: ${chain.join(' → ')}';

  @override
  List<Object?> get props => [instanceId, limit, chain];
}
