/// Compartilhado entre `NumberEditor` e `DimensionEditor`, para as duas nunca
/// divergirem no texto.
const invalidNumberMessage = 'Valor inválido';

/// `double.tryParse` aceita `"Infinity"`/`"NaN"` como número válido — o
/// spec (JSON) e o kernel (`clampToRange`, o `%` do `DimensionValue`) não
/// sabem lidar com nenhum dos dois, então os dois editores tratam isso como
/// texto não-parseável, igual a "abc".
double? tryParseFiniteDouble(String text) {
  final value = double.tryParse(text);
  return value != null && value.isFinite ? value : null;
}

num clampToRange(num raw, {num? min, num? max}) {
  var value = raw;
  if (min != null && value < min) value = min;
  if (max != null && value > max) value = max;
  return value;
}

String? clampMessageFor(num raw, num clamped, {required num? min}) {
  if (clamped == raw) return null;
  final isMinClamp = min != null && raw < min;
  return isMinClamp
      ? 'Ajustado para o mínimo (${formatClampedNumber(clamped)})'
      : 'Ajustado para o máximo (${formatClampedNumber(clamped)})';
}

String formatClampedNumber(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
