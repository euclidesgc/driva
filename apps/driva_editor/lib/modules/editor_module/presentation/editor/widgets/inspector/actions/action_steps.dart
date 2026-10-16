import 'package:sdui_core/sdui_core.dart';

typedef ActionSteps = List<Map<String, dynamic>>;

/// `[]` quando o gatilho falta ou chega malformado: o parse do kernel nunca
/// entrega isso, mas um passo cru não pode derrubar o inspector.
ActionSteps stepsOf(SduiNode node, EventTrigger trigger) {
  final raw = node.events[trigger.name];
  if (raw is! List || raw.any((step) => step is! Map)) return [];
  return [for (final step in raw) (step as Map).cast<String, dynamic>()];
}

/// O passo legado grava a ação em `type`; o editor só escreve `action`.
String? actionTypeOf(Map<String, dynamic> step) {
  final type = step['action'] ?? step['type'];
  return type is String ? type : null;
}

Map<String, dynamic> paramsOf(Map<String, dynamic> step) {
  final params = step['params'];
  return params is Map ? params.cast<String, dynamic>() : {};
}

/// Obrigatório sem default ganha o neutro do tipo para o rascunho continuar
/// salvável; opcional sem default fica ausente.
Object? neutralValueFor(PropField param) {
  if (param.defaultValue != null) return param.defaultValue;
  if (!param.isRequired) return null;
  return switch (param.kind) {
    FieldKind.string => '',
    FieldKind.intNum => 0,
    FieldKind.doubleNum => 0.0,
    FieldKind.boolean => false,
    FieldKind.enumeration when param.options.isNotEmpty =>
      param.options.first.value,
    _ => null,
  };
}

Map<String, dynamic> initialStep(ActionDescriptor action) => {
  'action': action.type,
  'params': {
    for (final param in action.params) param.key: ?neutralValueFor(param),
  },
};

ActionSteps withFirstStepAction(ActionSteps steps, ActionDescriptor action) => [
  initialStep(action),
  ...steps.skip(1),
];

ActionSteps withFirstStepParam(ActionSteps steps, String key, Object? value) {
  if (steps.isEmpty) return steps;
  final first = steps.first;
  final params = {...paramsOf(first)};
  if (value == null) {
    params.remove(key);
  } else {
    params[key] = value;
  }
  return [
    {...first, 'params': params},
    ...steps.skip(1),
  ];
}

/// A mesma regra do `bindNodeProp` do kernel: o valor fixo fica guardado por
/// baixo do binding para voltar ao desligar. A fonte legada não tem onde
/// guardá-lo.
Object? boundParamValue(Object? current, BoundPropValue binding) {
  if (binding.isLegacy) return binding.toJson();
  return BoundPropValue(
    source: binding.source,
    path: binding.path,
    transform: binding.transform,
    fallback: binding.fallback,
    preview: binding.preview,
    literal: literalUnder(current),
  ).toJson();
}

List<EventTrigger> configuredTriggers(
  SduiNode node,
  WidgetDescriptor descriptor,
) => [
  for (final trigger in descriptor.triggers)
    if (stepsOf(node, trigger).isNotEmpty) trigger,
];

List<EventTrigger> availableTriggers(
  SduiNode node,
  WidgetDescriptor descriptor,
) => [
  for (final trigger in descriptor.triggers)
    if (stepsOf(node, trigger).isEmpty) trigger,
];
