import 'package:sdui_core/src/catalog/field_kind.dart';
import 'package:sdui_core/src/catalog/prop_field.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';

/// Chrome da página, não um nó do documento: fica **fora** do `widgetCatalog`
/// de propósito. Toda página é embrulhada por uma área segura, então ela não
/// aparece na paleta, não entra na árvore e não pode ser selecionada — o
/// Inspector edita estas props quando nenhum widget está selecionado.
const WidgetDescriptor safeAreaDescriptor = WidgetDescriptor(
  type: 'safeArea',
  label: 'Área segura',
  iconName: 'safeArea',
  category: WidgetCategories.layout,
  slot: SlotKind.single,
  fields: [
    PropField(
      key: 'enabled',
      kind: FieldKind.boolean,
      label: 'Usar área segura',
      group: FieldGroups.layout,
      helpText:
          'Desligado, o conteúdo desenha embaixo do notch e da barra do '
          'sistema.',
      defaultValue: true,
      isBindable: false,
    ),
    PropField(
      key: 'top',
      kind: FieldKind.boolean,
      label: 'Respeitar o topo',
      group: FieldGroups.layout,
      defaultValue: true,
      isBindable: false,
    ),
    PropField(
      key: 'bottom',
      kind: FieldKind.boolean,
      label: 'Respeitar a base',
      group: FieldGroups.layout,
      defaultValue: true,
      isBindable: false,
    ),
    PropField(
      key: 'left',
      kind: FieldKind.boolean,
      label: 'Respeitar a esquerda',
      group: FieldGroups.layout,
      defaultValue: true,
      isBindable: false,
    ),
    PropField(
      key: 'right',
      kind: FieldKind.boolean,
      label: 'Respeitar a direita',
      group: FieldGroups.layout,
      defaultValue: true,
      isBindable: false,
    ),
    PropField(
      key: 'minimum',
      kind: FieldKind.edgeInsets,
      label: 'Espaçamento mínimo',
      group: FieldGroups.spacing,
      helpText: 'Aplicado mesmo onde o dispositivo não pede recuo.',
      isBindable: false,
    ),
    PropField(
      key: 'maintainBottomViewPadding',
      kind: FieldKind.boolean,
      label: 'Manter recuo do teclado',
      group: FieldGroups.layout,
      defaultValue: false,
      isAdvanced: true,
      isBindable: false,
    ),
  ],
);
