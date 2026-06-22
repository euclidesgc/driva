import 'package:flutter/widgets.dart';
import 'enums.dart';

/// Converte `#RRGGBB` ou `#AARRGGBB` em [Color]. Retorna `null` se inválido.
Color? parseColor(Object? value) {
  if (value is! String) return null;
  var hex = value.trim();
  if (!hex.startsWith('#')) return null;
  hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final intVal = int.tryParse(hex, radix: 16);
  if (intVal == null) return null;
  return Color(intVal);
}

/// Converte as três formas de EdgeInsets do spec (§3.1) em [EdgeInsets].
EdgeInsets? parseEdgeInsets(Object? value) {
  if (value is! Map) return null;
  final m = value.cast<String, dynamic>();
  double d(String k) => (m[k] as num?)?.toDouble() ?? 0;

  if (m.containsKey('all')) return EdgeInsets.all(d('all'));
  if (m.containsKey('horizontal') || m.containsKey('vertical')) {
    return EdgeInsets.symmetric(horizontal: d('horizontal'), vertical: d('vertical'));
  }
  return EdgeInsets.only(
    left: d('left'),
    top: d('top'),
    right: d('right'),
    bottom: d('bottom'),
  );
}

const _fontWeights = <String, FontWeight>{
  'w100': FontWeight.w100,
  'w200': FontWeight.w200,
  'w300': FontWeight.w300,
  'w400': FontWeight.w400,
  'w500': FontWeight.w500,
  'w600': FontWeight.w600,
  'w700': FontWeight.w700,
  'w800': FontWeight.w800,
  'w900': FontWeight.w900,
};

FontWeight? parseFontWeight(Object? v) => v is String ? _fontWeights[v] : null;

TextDecoration? parseTextDecoration(Object? v) {
  switch (v) {
    case 'underline':
      return TextDecoration.underline;
    case 'overline':
      return TextDecoration.overline;
    case 'lineThrough':
      return TextDecoration.lineThrough;
    case 'none':
      return TextDecoration.none;
    default:
      return null;
  }
}

/// Converte o objeto TextStyle do spec (§3.2) em [TextStyle].
TextStyle? parseTextStyle(Object? value) {
  if (value is! Map) return null;
  final m = value.cast<String, dynamic>();
  return TextStyle(
    fontSize: (m['fontSize'] as num?)?.toDouble(),
    fontWeight: parseFontWeight(m['fontWeight']),
    fontStyle: switch (m['fontStyle']) {
      'italic' => FontStyle.italic,
      'normal' => FontStyle.normal,
      _ => null,
    },
    color: parseColor(m['color']),
    fontFamily: m['fontFamily'] as String?,
    letterSpacing: (m['letterSpacing'] as num?)?.toDouble(),
    wordSpacing: (m['wordSpacing'] as num?)?.toDouble(),
    height: (m['height'] as num?)?.toDouble(),
    decoration: parseTextDecoration(m['decoration']),
  );
}

/// Converte um número (`num`) em `double`, ou `null`.
double? parseDouble(Object? v) => (v as num?)?.toDouble();

/// Resolve um valor de **dimensão** (spec `Dimension`) para um `double` concreto.
///
/// - `num`                                → o próprio valor (px fixo).
/// - `{ unit: "infinity" }`               → `double.infinity` (preenche o disponível).
/// - `{ unit: "screenWidth",  factor }`   → `MediaQuery.sizeOf(c).width  * factor`.
/// - `{ unit: "screenHeight", factor }`   → `MediaQuery.sizeOf(c).height * factor`.
///
/// `null` se ausente/irreconhecível. Bindings/tokens já foram resolvidos para
/// `num` no passe de binding antes de chegar aqui.
double? resolveDimension(BuildContext context, Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is Map) {
    final m = v.cast<String, dynamic>();
    final factor = (m['factor'] as num?)?.toDouble() ?? 1.0;
    switch (m['unit']) {
      case 'infinity':
        return double.infinity;
      case 'screenWidth':
        return MediaQuery.sizeOf(context).width * factor;
      case 'screenHeight':
        return MediaQuery.sizeOf(context).height * factor;
    }
  }
  return null;
}

/// BorderRadius — número uniforme ou `{ topLeft, topRight, bottomLeft, bottomRight }`.
BorderRadius? parseBorderRadius(Object? v) {
  if (v is num) return BorderRadius.circular(v.toDouble());
  if (v is Map) {
    final m = v.cast<String, dynamic>();
    Radius r(String k) => Radius.circular((m[k] as num?)?.toDouble() ?? 0);
    return BorderRadius.only(
      topLeft: r('topLeft'),
      topRight: r('topRight'),
      bottomLeft: r('bottomLeft'),
      bottomRight: r('bottomRight'),
    );
  }
  return null;
}

/// BoxConstraints — spec §2.1 (`constraints.*`).
BoxConstraints? parseBoxConstraints(Object? v) {
  if (v is! Map) return null;
  final m = v.cast<String, dynamic>();
  return BoxConstraints(
    minWidth: (m['minWidth'] as num?)?.toDouble() ?? 0.0,
    maxWidth: (m['maxWidth'] as num?)?.toDouble() ?? double.infinity,
    minHeight: (m['minHeight'] as num?)?.toDouble() ?? 0.0,
    maxHeight: (m['maxHeight'] as num?)?.toDouble() ?? double.infinity,
  );
}

Border? _parseBorder(Object? v) {
  if (v is! Map) return null;
  final m = v.cast<String, dynamic>();
  if (m['style'] == 'none') return null;
  return Border.all(
    color: parseColor(m['color']) ?? const Color(0xFF000000),
    width: (m['width'] as num?)?.toDouble() ?? 1.0,
  );
}

List<BoxShadow>? _parseBoxShadows(Object? v) {
  if (v is! List) return null;
  return [
    for (final item in v)
      if (item is Map)
        BoxShadow(
          color: parseColor(item['color']) ?? const Color(0xFF000000),
          offset: Offset(
            (item['offsetX'] as num?)?.toDouble() ?? 0,
            (item['offsetY'] as num?)?.toDouble() ?? 0,
          ),
          blurRadius: (item['blurRadius'] as num?)?.toDouble() ?? 0,
          spreadRadius: (item['spreadRadius'] as num?)?.toDouble() ?? 0,
        ),
  ];
}

Gradient? _parseGradient(Object? v) {
  if (v is! Map) return null;
  final m = v.cast<String, dynamic>();
  final colors = [
    for (final c in (m['colors'] as List? ?? const []))
      parseColor(c) ?? const Color(0x00000000),
  ];
  if (colors.isEmpty) return null;
  final stops = (m['stops'] as List?)?.map((s) => (s as num).toDouble()).toList();
  if (m['type'] == 'radial') {
    return RadialGradient(colors: colors, stops: stops);
  }
  return LinearGradient(
    colors: colors,
    stops: stops,
    begin: alignmentFrom(m['begin']) ?? Alignment.centerLeft,
    end: alignmentFrom(m['end']) ?? Alignment.centerRight,
  );
}

/// BoxDecoration — spec §3.3.
BoxDecoration? parseBoxDecoration(Object? v) {
  if (v is! Map) return null;
  final m = v.cast<String, dynamic>();
  final isCircle = m['shape'] == 'circle';
  return BoxDecoration(
    color: parseColor(m['color']),
    borderRadius: isCircle ? null : parseBorderRadius(m['borderRadius']),
    border: _parseBorder(m['border']),
    boxShadow: _parseBoxShadows(m['boxShadow']),
    gradient: _parseGradient(m['gradient']),
    shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
  );
}
