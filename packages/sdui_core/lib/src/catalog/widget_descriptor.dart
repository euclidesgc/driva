import 'package:equatable/equatable.dart';

import 'prop_field.dart';

enum SlotKind { none, single, multi }

class WidgetDescriptor extends Equatable {
  const WidgetDescriptor({
    required this.type,
    required this.label,
    required this.iconName,
    required this.category,
    required this.slot,
    this.fields = const [],
  });

  final String type;

  final String label;

  final String iconName;

  final String category;

  final SlotKind slot;

  final List<PropField> fields;

  @override
  List<Object?> get props => [type, label, iconName, category, slot, fields];
}

abstract final class WidgetCategories {
  static const layout = 'Layout';
  static const content = 'Conteúdo';
  static const interaction = 'Interação';
}
