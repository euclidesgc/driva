import 'package:flutter/widgets.dart';

/// Conversores de props cruas do spec em tipos do Flutter. O renderer recebe
/// o JSON cru (os defaults do catálogo já vêm preenchidos pelo editor, mas a
/// ausência também precisa funcionar — cada parser tem fallback).

/// Converte `#RRGGBB` ou `#AARRGGBB` em [Color]. `null` se inválido/ausente.
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

/// Converte as três formas de EdgeInsets do spec em [EdgeInsets]:
/// `{all}` | `{horizontal, vertical}` | `{left, top, right, bottom}`.
EdgeInsets? parseEdgeInsets(Object? value) {
  if (value is! Map) return null;
  final m = value.cast<String, dynamic>();
  double d(String k) => (m[k] as num?)?.toDouble() ?? 0;

  if (m.containsKey('all')) return EdgeInsets.all(d('all'));
  if (m.containsKey('horizontal') || m.containsKey('vertical')) {
    return EdgeInsets.symmetric(
      horizontal: d('horizontal'),
      vertical: d('vertical'),
    );
  }
  return EdgeInsets.only(
    left: d('left'),
    top: d('top'),
    right: d('right'),
    bottom: d('bottom'),
  );
}

double? parseDouble(Object? v) => (v as num?)?.toDouble();

int? parseInt(Object? v) => (v as num?)?.toInt();

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

/// BorderRadius uniforme a partir de um número.
BorderRadius? parseBorderRadius(Object? v) =>
    v is num ? BorderRadius.circular(v.toDouble()) : null;
