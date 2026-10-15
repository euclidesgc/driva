import 'package:equatable/equatable.dart';

/// Os valores comparados são escalares de JSON: a condição é dado de catálogo
/// `const`, nunca uma função.
sealed class VisibilityCondition extends Equatable {
  const VisibilityCondition();

  Set<String> get referencedKeys;
}

final class PropEquals extends VisibilityCondition {
  const PropEquals(this.key, this.value);

  final String key;
  final Object? value;

  @override
  Set<String> get referencedKeys => {key};

  @override
  List<Object?> get props => [key, value];
}

final class PropNotEquals extends VisibilityCondition {
  const PropNotEquals(this.key, this.value);

  final String key;
  final Object? value;

  @override
  Set<String> get referencedKeys => {key};

  @override
  List<Object?> get props => [key, value];
}

final class PropIn extends VisibilityCondition {
  const PropIn(this.key, this.values);

  final String key;
  final List<Object?> values;

  @override
  Set<String> get referencedKeys => {key};

  @override
  List<Object?> get props => [key, values];
}

final class AllOf extends VisibilityCondition {
  const AllOf(this.conditions);

  final List<VisibilityCondition> conditions;

  @override
  Set<String> get referencedKeys => {
    for (final condition in conditions) ...condition.referencedKeys,
  };

  @override
  List<Object?> get props => [conditions];
}

final class AnyOf extends VisibilityCondition {
  const AnyOf(this.conditions);

  final List<VisibilityCondition> conditions;

  @override
  Set<String> get referencedKeys => {
    for (final condition in conditions) ...condition.referencedKeys,
  };

  @override
  List<Object?> get props => [conditions];
}
