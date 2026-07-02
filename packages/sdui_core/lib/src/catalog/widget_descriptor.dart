import 'package:equatable/equatable.dart';

import 'prop_field.dart';

/// Que tipo de filho o primitivo aceita.
enum SlotKind {
  /// Folha: não aceita filho (`text`, `image`, `divider`...).
  none,

  /// Um filho único via `child` (`container`, `card`, `padding`...).
  single,

  /// N filhos via `children` (`column`, `row`, `stack`).
  multi,
}

/// Descreve um primitivo do catálogo: identidade, paleta e campos editáveis.
/// Paleta, Inspector e defaults do editor derivam 100% daqui.
class WidgetDescriptor extends Equatable {
  const WidgetDescriptor({
    required this.type,
    required this.label,
    required this.iconName,
    required this.category,
    required this.slot,
    this.fields = const [],
  });

  /// Identificador no spec (`container`, `text`, ...).
  final String type;

  /// Rótulo exibido na paleta (pt-BR).
  final String label;

  /// Ícone do item na paleta (nome do catálogo curado de Material Icons).
  final String iconName;

  /// Seção da paleta (rótulos centralizados em `WidgetCategories`).
  final String category;

  final SlotKind slot;

  final List<PropField> fields;

  @override
  List<Object?> get props => [type, label, iconName, category, slot, fields];
}

/// Seções da paleta, centralizadas para consistência.
abstract final class WidgetCategories {
  static const layout = 'Layout';
  static const content = 'Conteúdo';
  static const interaction = 'Interação';
}
