import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/component_instance.dart';

/// Fica **fora** do `widgetCatalog` de propósito: a paleta, o "Envolver com" e
/// o Inspector iteram o catálogo e ofereceriam uma instância sem
/// `componentId`. Só o `parseNode` o consulta.
const WidgetDescriptor componentInstanceDescriptor = WidgetDescriptor(
  type: ComponentInstance.type,
  label: 'Componente',
  iconName: 'widgets',
  category: WidgetCategories.basics,
  slot: SlotKind.none,
);
