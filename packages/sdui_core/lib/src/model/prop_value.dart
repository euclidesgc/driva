import 'package:equatable/equatable.dart';
import 'package:sdui_core/src/catalog/binding_source_ids.dart';

/// `SduiNode.properties` continua cru de propósito: esta família é só a
/// leitura tipada, feita sob demanda por `parsePropValue`.
sealed class PropValue extends Equatable {
  const PropValue();

  static const themeKey = r'$theme';
  static const bindKey = r'$bind';

  static bool isTypedForm(Object? raw) =>
      raw is Map && (raw.containsKey(themeKey) || raw.containsKey(bindKey));

  /// `parsePropValue(x.toJson())` devolve `x`.
  Object? toJson();
}

final class LiteralPropValue extends PropValue {
  const LiteralPropValue(this.value);

  final Object? value;

  @override
  Object? toJson() => value;

  @override
  List<Object?> get props => [value];
}

final class ThemeRefPropValue extends PropValue {
  const ThemeRefPropValue(this.token);

  final String token;

  @override
  Object? toJson() => {PropValue.themeKey: token};

  @override
  List<Object?> get props => [token];
}

/// O `{{expressão}}` legado não tem onde guardar os opcionais, por isso a
/// fonte `legacy` não os aceita.
final class BoundPropValue extends PropValue {
  const BoundPropValue({
    required this.source,
    required this.path,
    this.transform,
    this.fallback,
    this.preview,
    this.literal,
  }) : assert(
         source != BindingSourceIds.legacy ||
             (transform == null &&
                 fallback == null &&
                 preview == null &&
                 literal == null),
         'a fonte legacy não aceita transform/fallback/preview/literal',
       );

  const BoundPropValue.legacy(String path)
    : this(source: BindingSourceIds.legacy, path: path);

  final String source;

  final String path;

  final String? transform;

  final Object? fallback;

  final Object? preview;

  /// O valor fixo guardado por baixo: volta quando o binding é removido.
  final Object? literal;

  bool get isLegacy => source == BindingSourceIds.legacy;

  @override
  Object? toJson() {
    if (isLegacy) return '{{$path}}';
    return {
      PropValue.bindKey: {
        'source': source,
        'path': path,
        if (transform != null) 'transform': transform,
        if (fallback != null) 'fallback': fallback,
        if (preview != null) 'preview': preview,
        if (literal != null) 'literal': literal,
      },
    };
  }

  @override
  List<Object?> get props => [
    source,
    path,
    transform,
    fallback,
    preview,
    literal,
  ];
}
