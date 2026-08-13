import 'package:equatable/equatable.dart';

/// Largura/altura no spec em três formas, no padrão do FlutterFlow:
/// número = pixels, `"70%"` = fração do pai, `"inf"` = preenche o disponível.
///
/// Número cru continua sendo pixels, então todo spec já escrito segue válido.
/// A String não colide com `{{binding}}`: o binding embrulha o valor inteiro e
/// é reconhecido antes, por `SduiBinding`.
sealed class DimensionValue extends Equatable {
  const DimensionValue();

  static const infiniteToken = 'inf';

  static final _percent = RegExp(r'^(\d+(?:[.,]\d+)?)\s*%$');

  /// `null` para ausência ou forma que não é dimensão — inclusive um binding,
  /// que o editor trata numa camada acima.
  static DimensionValue? parse(Object? raw) {
    if (raw is num) return PixelDimension(raw.toDouble());
    if (raw is! String) return null;

    final trimmed = raw.trim();
    if (trimmed == infiniteToken) return const InfiniteDimension();

    final match = _percent.firstMatch(trimmed);
    if (match == null) return null;

    final number = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    return number == null ? null : PercentDimension(number / 100);
  }

  /// A forma que vai para o JSON. `parse(x.toJson())` devolve `x`.
  Object toJson();
}

final class PixelDimension extends DimensionValue {
  const PixelDimension(this.pixels);

  final double pixels;

  @override
  Object toJson() => pixels;

  @override
  List<Object?> get props => [pixels];
}

/// [fraction] é 0..1 — `"70%"` vira `0.7`.
final class PercentDimension extends DimensionValue {
  const PercentDimension(this.fraction);

  final double fraction;

  @override
  Object toJson() {
    final percent = fraction * 100;
    final rounded = percent.roundToDouble();
    return '${percent == rounded ? rounded.toInt() : percent}%';
  }

  @override
  List<Object?> get props => [fraction];
}

final class InfiniteDimension extends DimensionValue {
  const InfiniteDimension();

  @override
  Object toJson() => DimensionValue.infiniteToken;

  @override
  List<Object?> get props => const [];
}
