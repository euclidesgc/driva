import 'package:sdui_core/src/model/edge_insets_mode.dart';

/// Espaçamento no spec: `{all: X}` ou os lados `left/top/right/bottom`
/// presentes. `all`, quando existe, vale para os quatro lados.
abstract final class EdgeInsetsValue {
  static const allKey = 'all';
  static const sides = ['left', 'top', 'right', 'bottom'];

  static double? sideOf(Object? raw, String side) {
    if (raw is! Map) return null;
    if (raw.containsKey(allKey)) return _number(raw[allKey]);
    return _number(raw[side]);
  }

  /// `null` quando os lados divergem ou não há valor.
  static double? uniformOf(Object? raw) {
    if (raw is! Map) return null;
    if (raw.containsKey(allKey)) return _number(raw[allKey]);
    final distinct = _distinctSides(raw);
    return distinct.length == 1 ? distinct.first : null;
  }

  static EdgeInsetsMode modeOf(Object? raw) {
    if (raw is! Map) return EdgeInsetsMode.uniform;
    if (raw.containsKey(allKey)) return EdgeInsetsMode.uniform;
    return _distinctSides(raw).length == 1
        ? EdgeInsetsMode.uniform
        : EdgeInsetsMode.perSide;
  }

  static Set<double?> _distinctSides(Map<dynamic, dynamic> raw) => {
    for (final side in sides) _number(raw[side]),
  };

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : null;
}
