import 'package:flutter/material.dart';

/// Subconjunto curado de Material Icons. `IconData` const não pode ser
/// resolvido por nome em runtime (tree-shaking), então mantemos um mapa
/// explícito; cresce conforme a necessidade. O seletor de ícones do editor
/// lê [curatedIconNames].
const _icons = <String, IconData>{
  'home': Icons.home,
  'settings': Icons.settings,
  'add': Icons.add,
  'remove': Icons.remove,
  'search': Icons.search,
  'menu': Icons.menu,
  'close': Icons.close,
  'check': Icons.check,
  'favorite': Icons.favorite,
  'star': Icons.star,
  'shoppingCart': Icons.shopping_cart,
  'arrowBack': Icons.arrow_back,
  'arrowForward': Icons.arrow_forward,
  'delete': Icons.delete,
  'edit': Icons.edit,
  'person': Icons.person,
  'info': Icons.info,
  'warning': Icons.warning,
};

IconData? iconDataFrom(Object? v) => v is String ? _icons[v] : null;

/// Nomes disponíveis, para o seletor do Inspector.
List<String> get curatedIconNames => _icons.keys.toList(growable: false);
