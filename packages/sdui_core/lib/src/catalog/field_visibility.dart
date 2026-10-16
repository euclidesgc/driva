import 'package:sdui_core/src/catalog/prop_field.dart';
import 'package:sdui_core/src/catalog/visibility_condition.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_binding.dart';

/// Avalia `PropField.visibleWhen` sobre o valor cru das props do nó, sem
/// cascata: nunca pergunta se a prop de controle está, ela mesma, visível.
abstract final class FieldVisibility {
  static bool isVisible(
    PropField field,
    Map<String, dynamic> properties,
    WidgetDescriptor descriptor, {
    Set<String> indeterminateKeys = const {},
  }) {
    final condition = field.visibleWhen;
    if (condition == null) return true;
    return evaluate(
      condition,
      properties,
      descriptor,
      indeterminateKeys: indeterminateKeys,
    );
  }

  static bool evaluate(
    VisibilityCondition condition,
    Map<String, dynamic> properties,
    WidgetDescriptor descriptor, {
    Set<String> indeterminateKeys = const {},
  }) {
    bool leaf(String key, bool Function(Object? raw) test) =>
        indeterminateKeys.contains(key) ||
        _leaf(key, properties, descriptor, test);

    return switch (condition) {
      PropEquals(:final key, :final value) => leaf(key, (raw) => raw == value),
      PropNotEquals(:final key, :final value) => leaf(
        key,
        (raw) => raw != value,
      ),
      PropIn(:final key, :final values) => leaf(key, values.contains),
      AllOf(:final conditions) => conditions.every(
        (c) => evaluate(
          c,
          properties,
          descriptor,
          indeterminateKeys: indeterminateKeys,
        ),
      ),
      AnyOf(:final conditions) => conditions.any(
        (c) => evaluate(
          c,
          properties,
          descriptor,
          indeterminateKeys: indeterminateKeys,
        ),
      ),
    };
  }

  static List<String> problemsIn(WidgetDescriptor descriptor) {
    final problems = <String>[];
    for (final field in descriptor.fields) {
      final condition = field.visibleWhen;
      if (condition == null) continue;
      final where = '${descriptor.type}.${field.key}';
      if (_hasEmptyComposite(condition)) {
        problems.add('$where: visibleWhen tem AllOf/AnyOf sem condições');
      }
      for (final key in condition.referencedKeys) {
        if (key == field.key) {
          problems.add('$where: visibleWhen referencia o próprio campo');
        } else if (descriptor.fieldOf(key) == null) {
          problems.add('$where: visibleWhen referencia "$key", que não existe');
        }
      }
    }
    return problems;
  }

  static bool _hasEmptyComposite(VisibilityCondition condition) =>
      switch (condition) {
        PropEquals() || PropNotEquals() || PropIn() => false,
        AllOf(:final conditions) || AnyOf(:final conditions) =>
          conditions.isEmpty || conditions.any(_hasEmptyComposite),
      };

  /// Binding, token ou prop que o descriptor não declara (o lote só conhece os
  /// campos comuns) deixam o valor de controle indeterminado: a folha dá
  /// `true` para o campo não sumir sem o autor saber o valor final.
  static bool _leaf(
    String key,
    Map<String, dynamic> properties,
    WidgetDescriptor descriptor,
    bool Function(Object? raw) test,
  ) {
    if (descriptor.fieldOf(key) == null) return true;
    final stored = properties[key];
    final raw = stored ?? descriptor.defaultValueOf(key);
    if (SduiBinding.isBinding(raw) || PropValue.isTypedForm(raw)) return true;
    return test(raw);
  }
}
