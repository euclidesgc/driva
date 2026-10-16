import 'package:equatable/equatable.dart';
import 'package:sdui_core/src/model/component_param_type.dart';

class ComponentStateVariable extends Equatable {
  const ComponentStateVariable({
    required this.name,
    required this.type,
    required this.isList,
    this.defaultValue,
    this.description,
    this.options = const [],
  });

  final String name;
  final ComponentParamType type;
  final bool isList;
  final Object? defaultValue;
  final String? description;
  final List<String> options;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'isList': isList,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
      if (options.isNotEmpty) 'options': options,
    };
  }

  @override
  List<Object?> get props => [
    name,
    type,
    isList,
    defaultValue,
    description,
    options,
  ];
}
