/// Alinhamento no spec em duas formas: o nome do preset (`'topLeft'`) ou o par
/// livre (`{x, y}`), com `x`/`y` em -1..1 como no `Alignment` do Flutter.
///
/// [encode] prefere o nome sempre que o par cai numa das nove posições
/// canônicas — o JSON só fica verboso quando precisa ser, e ler-e-escrever não
/// altera um spec já existente.
abstract final class AlignmentValue {
  static const presets = <String, ({double x, double y})>{
    'topLeft': (x: -1, y: -1),
    'topCenter': (x: 0, y: -1),
    'topRight': (x: 1, y: -1),
    'centerLeft': (x: -1, y: 0),
    'center': (x: 0, y: 0),
    'centerRight': (x: 1, y: 0),
    'bottomLeft': (x: -1, y: 1),
    'bottomCenter': (x: 0, y: 1),
    'bottomRight': (x: 1, y: 1),
  };

  /// `null` para ausência ou forma irreconhecível — inclusive um binding.
  static ({double x, double y})? parse(Object? raw) {
    if (raw is String) return presets[raw];
    if (raw is! Map) return null;

    final x = _axis(raw['x']);
    final y = _axis(raw['y']);
    if (x == null && y == null) return null;
    return (x: x ?? 0, y: y ?? 0);
  }

  static Object encode({required double x, required double y}) {
    for (final entry in presets.entries) {
      if (entry.value.x == x && entry.value.y == y) return entry.key;
    }
    return {'x': x, 'y': y};
  }

  static String? presetNameOf(Object? raw) {
    final pair = parse(raw);
    if (pair == null) return null;
    final encoded = encode(x: pair.x, y: pair.y);
    return encoded is String ? encoded : null;
  }

  static double? _axis(Object? value) => value is num ? value.toDouble() : null;
}
