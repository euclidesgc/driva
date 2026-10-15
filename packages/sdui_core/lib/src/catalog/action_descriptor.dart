import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/prop_field.dart';

/// Os parâmetros são `PropField` para o editor desenhá-los com os mesmos
/// editores das props, sem um tipo de campo próprio de ação.
class ActionDescriptor extends Equatable {
  const ActionDescriptor({
    required this.type,
    required this.label,
    required this.iconName,
    required this.category,
    this.params = const [],
    this.contexts = const {BindingContext.page, BindingContext.component},
  });

  final String type;

  final String label;

  final String iconName;

  final String category;

  final List<PropField> params;

  final Set<BindingContext> contexts;

  PropField? paramOf(String key) {
    for (final param in params) {
      if (param.key == key) return param;
    }
    return null;
  }

  bool isAvailableIn(BindingContext context) => contexts.contains(context);

  Iterable<PropField> get requiredParams => params.where((p) => p.isRequired);

  @override
  List<Object?> get props => [
    type,
    label,
    iconName,
    category,
    params,
    contexts,
  ];
}

abstract final class ActionCategories {
  static const navigation = 'Navegação';
  static const alerts = 'Alertas';
  static const utilities = 'Utilitários';
  static const backend = 'Backend';

  /// Ordem em que o seletor de ações agrupa as categorias.
  static const List<String> inPickerOrder = [
    navigation,
    alerts,
    utilities,
    backend,
  ];
}
