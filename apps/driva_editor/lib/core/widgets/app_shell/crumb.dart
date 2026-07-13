import 'package:flutter/foundation.dart';

/// Um nível do breadcrumb global. Clicável quando [routeName] != null.
///
/// A página publica a lista inteira de crumbs (ela conhece os labels dinâmicos
/// — nome do projeto/conteúdo); o shell só renderiza dados opacos.
@immutable
class Crumb {
  const Crumb({
    required this.label,
    this.routeName,
    this.pathParameters = const {},
  });

  final String label;
  final String? routeName;
  final Map<String, String> pathParameters;

  @override
  bool operator ==(Object other) =>
      other is Crumb &&
      other.label == label &&
      other.routeName == routeName &&
      mapEquals(other.pathParameters, pathParameters);

  @override
  int get hashCode => Object.hash(
    label,
    routeName,
    Object.hashAll(
      pathParameters.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
