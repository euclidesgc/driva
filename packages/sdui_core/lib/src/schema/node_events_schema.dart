import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/catalog/action_catalog.dart';
import 'package:sdui_core/src/catalog/action_descriptor.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/event_trigger.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/schema/node_props_schema.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';

/// Devolve os eventos que o nó guarda: no estrito, os de entrada; no
/// tolerante, sem o gatilho e o passo que o kernel não conhece. Erro de
/// estrutura e parâmetro obrigatório ausente recusam nos dois modos, como as
/// props. O passo é guardado cru (sem trocar `type` por `action`) para que o
/// round-trip seja exato e o fluxo de ações possa acrescentar chaves a ele.
Either<SpecValidationError, Map<String, dynamic>> parseNodeEvents(
  Map<String, dynamic> events,
  WidgetDescriptor descriptor, {
  required String path,
  required int specVersion,
  required bool tolerant,
  BindingContext context = BindingContext.page,
  Iterable<ActionDescriptor> actions = actionCatalog,
}) {
  final kept = <String, dynamic>{};
  var dropped = false;

  for (final MapEntry(key: name, value: rawSteps) in events.entries) {
    final triggerPath = '$path.$name';
    final trigger = EventTrigger.byName(name);
    final triggerError = trigger == null
        ? '$triggerPath: gatilho desconhecido'
        : descriptor.declaresTrigger(trigger)
        ? null
        : '$triggerPath: "${descriptor.type}" não oferece o gatilho $name';
    if (triggerError != null) {
      if (!tolerant) return Left(SpecValidationError(triggerError));
      dropped = true;
      continue;
    }

    if (rawSteps is! List) {
      return Left(
        SpecValidationError('$triggerPath: esperada uma lista de ações'),
      );
    }

    final steps = <dynamic>[];
    for (var i = 0; i < rawSteps.length; i++) {
      final step = _parseStep(
        rawSteps[i],
        path: '$triggerPath[$i]',
        specVersion: specVersion,
        tolerant: tolerant,
        context: context,
        actions: actions,
      );
      switch (step) {
        case Left(:final value):
          return Left(value);
        case Right(value: null):
          dropped = true;
        case Right(value: final parsed?):
          steps.add(parsed);
      }
    }
    if (rawSteps.isNotEmpty && steps.isEmpty) continue;
    kept[name] = steps.length == rawSteps.length ? rawSteps : steps;
  }

  return Right(dropped ? kept : events);
}

/// `Right(null)` = passo descartado pelo tolerante.
Either<SpecValidationError, Object?> _parseStep(
  Object? raw, {
  required String path,
  required int specVersion,
  required bool tolerant,
  required BindingContext context,
  required Iterable<ActionDescriptor> actions,
}) {
  if (raw is! Map) {
    return Left(SpecValidationError('$path: esperado um objeto'));
  }

  final type = raw['action'] ?? raw['type'];
  if (type is! String || type.isEmpty) {
    return Left(SpecValidationError('$path.action: ação ausente'));
  }

  final action = actionFor(type, actions: actions);
  final actionError = action == null
      ? 'ação "$type" fora do catálogo'
      : action.isAvailableIn(context)
      ? null
      : 'ação "$type" não está disponível em ${_contextLabel(context)}';
  if (actionError != null) {
    if (tolerant) return const Right(null);
    return Left(SpecValidationError('$path.action: $actionError'));
  }

  final rawParams = raw['params'];
  if (rawParams != null && rawParams is! Map) {
    return Left(SpecValidationError('$path.params: esperado um objeto'));
  }
  final params = (rawParams as Map?)?.cast<String, dynamic>() ?? const {};

  for (final param in action!.requiredParams) {
    if (params[param.key] == null) {
      return Left(
        SpecValidationError(
          '$path.params.${param.key}: parâmetro obrigatório ausente',
        ),
      );
    }
  }

  return validateFieldValues(
    params,
    action.params,
    path: '$path.params',
    specVersion: specVersion,
    context: context,
    tolerant: tolerant,
  ).map((_) => raw);
}

String _contextLabel(BindingContext context) => switch (context) {
  BindingContext.page => 'página',
  BindingContext.component => 'componente',
  BindingContext.action => 'ação',
};
