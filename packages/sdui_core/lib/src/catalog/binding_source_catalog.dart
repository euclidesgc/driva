import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/binding_source.dart';
import 'package:sdui_core/src/catalog/binding_source_ids.dart';
import 'package:sdui_core/src/catalog/prop_value_type.dart';

const List<BindingSource> bindingSourceCatalog = [
  BindingSource(
    id: BindingSourceIds.legacy,
    label: 'Expressão livre',
    outputType: PropValueType.any,
    contexts: {
      BindingContext.page,
      BindingContext.component,
      BindingContext.action,
    },
  ),
  BindingSource(
    id: BindingSourceIds.pageParam,
    label: 'Parâmetro da página',
    outputType: PropValueType.declared,
    contexts: {BindingContext.page, BindingContext.component},
  ),
  BindingSource(
    id: BindingSourceIds.componentParam,
    label: 'Parâmetro do componente',
    outputType: PropValueType.declared,
    contexts: {BindingContext.component},
  ),
  BindingSource(
    id: BindingSourceIds.actionResult,
    label: 'Resultado de ação',
    outputType: PropValueType.declared,
    contexts: {BindingContext.action},
  ),
];

BindingSource? bindingSourceFor(String id) {
  for (final source in bindingSourceCatalog) {
    if (source.id == id) return source;
  }
  return null;
}

List<BindingSource> bindingSourcesFor(
  BindingContext context, {
  PropValueType? feeding,
  Iterable<BindingSource> sources = bindingSourceCatalog,
}) => [
  for (final source in sources)
    if (source.isAvailableIn(context) &&
        (feeding == null || source.feeds(feeding)))
      source,
];
