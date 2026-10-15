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
    WidgetDescriptor descriptor,
  ) {
    final condition = field.visibleWhen;
    if (condition == null) return true;
    return evaluate(condition, properties, descriptor);
  }

  static bool evaluate(
    VisibilityCondition condition,
    Map<String, dynamic> properties,
    WidgetDescriptor descriptor,
  ) {
    return switch (condition) {
      PropEquals(:final key, :final value) => _leaf(
        key,
        properties,
        descriptor,
        (raw) => raw == value,
      ),
      PropNotEquals(:final key, :final value) => _leaf(
        key,
        properties,
        descriptor,
        (raw) => raw != value,
      ),
      PropIn(:final key, :final values) => _leaf(
        key,
        properties,
        descriptor,
        values.contains,
      ),
      AllOf(:final conditions) => conditions.every(
        (c) => evaluate(c, properties, descriptor),
      ),
      AnyOf(:final conditions) => conditions.any(
        (c) => evaluate(c, properties, descriptor),
      ),
    };
  }

  /// Lista vazia significa descriptor coerente.
  static List<String> problemsIn(WidgetDescriptor descriptor) {
    final problems = <String>[];
    for (final field in descriptor.fields) {
      final condition = field.visibleWhen;
      if (condition == null) continue;
      for (final key in condition.referencedKeys) {
        final where = '${descriptor.type}.${field.key}';
        if (key == field.key) {
          problems.add('$where: visibleWhen referencia o próprio campo');
        } else if (descriptor.fieldOf(key) == null) {
          problems.add('$where: visibleWhen referencia "$key", que não existe');
        }
      }
    }
    return problems;
  }

  /// Binding ou token no valor de controle é indeterminado: a folha dá `true`
  /// para o campo não sumir sem o autor saber o valor final.
  static bool _leaf(
    String key,
    Map<String, dynamic> properties,
    WidgetDescriptor descriptor,
    bool Function(Object? raw) test,
  ) {
    final stored = properties[key];
    final raw = stored ?? descriptor.defaultValueOf(key);
    if (SduiBinding.isBinding(raw) || PropValue.isTypedForm(raw)) return true;
    return test(raw);
  }
}
