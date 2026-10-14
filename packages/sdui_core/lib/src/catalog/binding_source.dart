import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/prop_value_type.dart';

class BindingSource extends Equatable {
  const BindingSource({
    required this.id,
    required this.label,
    required this.outputType,
    required this.contexts,
  });

  final String id;

  final String label;

  final PropValueType outputType;

  final Set<BindingContext> contexts;

  bool isAvailableIn(BindingContext context) => contexts.contains(context);

  bool feeds(PropValueType expected) => outputType.feeds(expected);

  @override
  List<Object?> get props => [id, label, outputType, contexts];
}
