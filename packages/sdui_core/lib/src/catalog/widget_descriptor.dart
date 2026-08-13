import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/catalog/prop_field.dart';

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

  PropField? fieldOf(String key) {
    for (final field in fields) {
      if (field.key == key) return field;
    }
    return null;
  }

  Object? defaultValueOf(String key) => fieldOf(key)?.defaultValue;

  @override
  List<Object?> get props => [type, label, iconName, category, slot, fields];
}

/// Espelha a divisão da paleta do FlutterFlow (Base / Layout / Form), com as
/// listas separadas por serem os únicos primitivos que repetem um filho.
abstract final class WidgetCategories {
  static const basics = 'Básicos';
  static const layout = 'Layout';
  static const form = 'Formulário';
  static const lists = 'Listas';

  /// Ordem em que a paleta agrupa as categorias.
  static const List<String> inPaletteOrder = [basics, layout, form, lists];
}
