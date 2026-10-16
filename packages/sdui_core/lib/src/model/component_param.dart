import 'package:equatable/equatable.dart';
import 'package:sdui_core/src/model/component_param_type.dart';

class ComponentParam extends Equatable {
  const ComponentParam({
    required this.name,
    required this.type,
    required this.isList,
    required this.isRequired,
    this.defaultValue,
    this.description,
    this.options = const [],
    this.callbackParams = const [],
  });

  final String name;
  final ComponentParamType type;
  final bool isList;
  final bool isRequired;
  final Object? defaultValue;
  final String? description;
  final List<String> options;
  final List<ComponentParam> callbackParams;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'isList': isList,
      'required': isRequired,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
      if (options.isNotEmpty) 'options': options,
      if (callbackParams.isNotEmpty)
        'params': [for (final param in callbackParams) param.toJson()],
    };
  }

  @override
  List<Object?> get props => [
    name,
    type,
    isList,
    isRequired,
    defaultValue,
    description,
    options,
    callbackParams,
  ];
}
