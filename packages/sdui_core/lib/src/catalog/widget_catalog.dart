import '../model/sdui_node.dart';
import 'field_kind.dart';
import 'prop_field.dart';
import 'widget_descriptor.dart';

// Campos compartilhados pelos primitivos flex (column/row).
const List<PropField> _flexFields = [
  PropField(
    key: 'mainAxisAlignment',
    kind: FieldKind.enumeration,
    label: 'Alinhamento principal',
    group: FieldGroups.layout,
    enumValues: [
      'start',
      'end',
      'center',
      'spaceBetween',
      'spaceAround',
      'spaceEvenly',
    ],
    defaultValue: 'start',
  ),
  PropField(
    key: 'crossAxisAlignment',
    kind: FieldKind.enumeration,
    label: 'Alinhamento cruzado',
    group: FieldGroups.layout,
    enumValues: ['start', 'end', 'center', 'stretch'],
    defaultValue: 'center',
  ),
  PropField(
    key: 'mainAxisSize',
    kind: FieldKind.enumeration,
    label: 'Tamanho do eixo',
    group: FieldGroups.layout,
    enumValues: ['max', 'min'],
    defaultValue: 'max',
  ),
  PropField(
    key: 'spacing',
    kind: FieldKind.doubleNum,
    label: 'Espaço entre filhos',
    group: FieldGroups.spacing,
    defaultValue: 0.0,
  ),
];

/// Catálogo dos primitivos do I1. Adicionar um primitivo = um descriptor aqui
/// + um builder no `sdui_flutter` + uma fixture de teste.
///
/// As props são **planas** de propósito (ex.: `fontSize` direto no `text`, em
/// vez de um objeto `style` aninhado): o Inspector do I1 edita campo a campo.
final Map<String, WidgetDescriptor> widgetCatalog = Map.unmodifiable({
  'container': const WidgetDescriptor(
    type: 'container',
    label: 'Container',
    iconName: 'container',
    category: WidgetCategories.layout,
    slot: SlotKind.single,
    fields: [
      PropField(
        key: 'width',
        kind: FieldKind.doubleNum,
        label: 'Largura',
        group: FieldGroups.size,
      ),
      PropField(
        key: 'height',
        kind: FieldKind.doubleNum,
        label: 'Altura',
        group: FieldGroups.size,
      ),
      PropField(
        key: 'padding',
        kind: FieldKind.edgeInsets,
        label: 'Padding',
        group: FieldGroups.spacing,
      ),
      PropField(
        key: 'margin',
        kind: FieldKind.edgeInsets,
        label: 'Margin',
        group: FieldGroups.spacing,
      ),
      PropField(
        key: 'alignment',
        kind: FieldKind.alignment,
        label: 'Alinhamento do filho',
        group: FieldGroups.layout,
      ),
      PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor de fundo',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'borderRadius',
        kind: FieldKind.doubleNum,
        label: 'Raio da borda',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'borderColor',
        kind: FieldKind.color,
        label: 'Cor da borda',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'borderWidth',
        kind: FieldKind.doubleNum,
        label: 'Espessura da borda',
        group: FieldGroups.style,
      ),
    ],
  ),
  'column': const WidgetDescriptor(
    type: 'column',
    label: 'Column',
    iconName: 'column',
    category: WidgetCategories.layout,
    slot: SlotKind.multi,
    fields: _flexFields,
  ),
  'row': const WidgetDescriptor(
    type: 'row',
    label: 'Row',
    iconName: 'row',
    category: WidgetCategories.layout,
    slot: SlotKind.multi,
    fields: _flexFields,
  ),
  'stack': const WidgetDescriptor(
    type: 'stack',
    label: 'Stack',
    iconName: 'stack',
    category: WidgetCategories.layout,
    slot: SlotKind.multi,
    fields: [
      PropField(
        key: 'alignment',
        kind: FieldKind.alignment,
        label: 'Alinhamento',
        group: FieldGroups.layout,
      ),
      PropField(
        key: 'fit',
        kind: FieldKind.enumeration,
        label: 'Ajuste',
        group: FieldGroups.layout,
        enumValues: ['loose', 'expand', 'passthrough'],
        defaultValue: 'loose',
      ),
    ],
  ),
  'text': const WidgetDescriptor(
    type: 'text',
    label: 'Text',
    iconName: 'text',
    category: WidgetCategories.content,
    slot: SlotKind.none,
    fields: [
      PropField(
        key: 'data',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
        defaultValue: 'Texto',
        isRequired: true,
      ),
      PropField(
        key: 'fontSize',
        kind: FieldKind.doubleNum,
        label: 'Tamanho da fonte',
        group: FieldGroups.style,
        defaultValue: 14.0,
      ),
      PropField(
        key: 'fontWeight',
        kind: FieldKind.enumeration,
        label: 'Peso da fonte',
        group: FieldGroups.style,
        enumValues: [
          'w100',
          'w200',
          'w300',
          'w400',
          'w500',
          'w600',
          'w700',
          'w800',
          'w900',
        ],
        defaultValue: 'w400',
      ),
      PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'textAlign',
        kind: FieldKind.enumeration,
        label: 'Alinhamento do texto',
        group: FieldGroups.content,
        enumValues: ['start', 'end', 'left', 'right', 'center', 'justify'],
        defaultValue: 'start',
      ),
      PropField(
        key: 'maxLines',
        kind: FieldKind.intNum,
        label: 'Máximo de linhas',
        group: FieldGroups.content,
      ),
      PropField(
        key: 'overflow',
        kind: FieldKind.enumeration,
        label: 'Overflow',
        group: FieldGroups.content,
        enumValues: ['clip', 'fade', 'ellipsis', 'visible'],
        defaultValue: 'clip',
      ),
    ],
  ),
  'image': const WidgetDescriptor(
    type: 'image',
    label: 'Image',
    iconName: 'image',
    category: WidgetCategories.content,
    slot: SlotKind.none,
    fields: [
      PropField(
        key: 'src',
        kind: FieldKind.string,
        label: 'URL da imagem',
        group: FieldGroups.content,
        isRequired: true,
      ),
      PropField(
        key: 'width',
        kind: FieldKind.doubleNum,
        label: 'Largura',
        group: FieldGroups.size,
      ),
      PropField(
        key: 'height',
        kind: FieldKind.doubleNum,
        label: 'Altura',
        group: FieldGroups.size,
      ),
      PropField(
        key: 'fit',
        kind: FieldKind.enumeration,
        label: 'Ajuste',
        group: FieldGroups.content,
        enumValues: [
          'fill',
          'contain',
          'cover',
          'fitWidth',
          'fitHeight',
          'none',
          'scaleDown',
        ],
        defaultValue: 'contain',
      ),
    ],
  ),
  'icon': const WidgetDescriptor(
    type: 'icon',
    label: 'Icon',
    iconName: 'icon',
    category: WidgetCategories.content,
    slot: SlotKind.none,
    fields: [
      PropField(
        key: 'icon',
        kind: FieldKind.iconName,
        label: 'Ícone',
        group: FieldGroups.content,
        defaultValue: 'star',
        isRequired: true,
      ),
      PropField(
        key: 'size',
        kind: FieldKind.doubleNum,
        label: 'Tamanho',
        group: FieldGroups.style,
        defaultValue: 24.0,
      ),
      PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      ),
    ],
  ),
  'button': const WidgetDescriptor(
    type: 'button',
    label: 'Button',
    iconName: 'button',
    category: WidgetCategories.interaction,
    slot: SlotKind.none,
    fields: [
      PropField(
        key: 'label',
        kind: FieldKind.string,
        label: 'Rótulo',
        group: FieldGroups.content,
        defaultValue: 'Botão',
        isRequired: true,
      ),
      PropField(
        key: 'variant',
        kind: FieldKind.enumeration,
        label: 'Variante',
        group: FieldGroups.style,
        enumValues: ['elevated', 'filled', 'outlined', 'text'],
        defaultValue: 'elevated',
      ),
      PropField(
        key: 'backgroundColor',
        kind: FieldKind.color,
        label: 'Cor de fundo',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'foregroundColor',
        kind: FieldKind.color,
        label: 'Cor do conteúdo',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'borderRadius',
        kind: FieldKind.doubleNum,
        label: 'Raio da borda',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'fontSize',
        kind: FieldKind.doubleNum,
        label: 'Tamanho da fonte',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'enabled',
        kind: FieldKind.boolean,
        label: 'Habilitado',
        group: FieldGroups.content,
        defaultValue: true,
      ),
    ],
  ),
  'card': const WidgetDescriptor(
    type: 'card',
    label: 'Card',
    iconName: 'card',
    category: WidgetCategories.layout,
    slot: SlotKind.single,
    fields: [
      PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'elevation',
        kind: FieldKind.doubleNum,
        label: 'Elevação',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'borderRadius',
        kind: FieldKind.doubleNum,
        label: 'Raio da borda',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'margin',
        kind: FieldKind.edgeInsets,
        label: 'Margin',
        group: FieldGroups.spacing,
      ),
    ],
  ),
  'divider': const WidgetDescriptor(
    type: 'divider',
    label: 'Divider',
    iconName: 'divider',
    category: WidgetCategories.layout,
    slot: SlotKind.none,
    fields: [
      PropField(
        key: 'thickness',
        kind: FieldKind.doubleNum,
        label: 'Espessura',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      ),
      PropField(
        key: 'indent',
        kind: FieldKind.doubleNum,
        label: 'Recuo inicial',
        group: FieldGroups.spacing,
      ),
      PropField(
        key: 'endIndent',
        kind: FieldKind.doubleNum,
        label: 'Recuo final',
        group: FieldGroups.spacing,
      ),
    ],
  ),
  'sizedBox': const WidgetDescriptor(
    type: 'sizedBox',
    label: 'SizedBox',
    iconName: 'sizedBox',
    category: WidgetCategories.layout,
    slot: SlotKind.single,
    fields: [
      PropField(
        key: 'width',
        kind: FieldKind.doubleNum,
        label: 'Largura',
        group: FieldGroups.size,
      ),
      PropField(
        key: 'height',
        kind: FieldKind.doubleNum,
        label: 'Altura',
        group: FieldGroups.size,
      ),
    ],
  ),
  'padding': const WidgetDescriptor(
    type: 'padding',
    label: 'Padding',
    iconName: 'padding',
    category: WidgetCategories.layout,
    slot: SlotKind.single,
    fields: [
      PropField(
        key: 'padding',
        kind: FieldKind.edgeInsets,
        label: 'Padding',
        group: FieldGroups.spacing,
        defaultValue: {'all': 8.0},
        isRequired: true,
      ),
    ],
  ),
  'center': const WidgetDescriptor(
    type: 'center',
    label: 'Center',
    iconName: 'center',
    category: WidgetCategories.layout,
    slot: SlotKind.single,
    fields: [
      PropField(
        key: 'widthFactor',
        kind: FieldKind.doubleNum,
        label: 'Fator de largura',
        group: FieldGroups.size,
      ),
      PropField(
        key: 'heightFactor',
        kind: FieldKind.doubleNum,
        label: 'Fator de altura',
        group: FieldGroups.size,
      ),
    ],
  ),
  'spacer': const WidgetDescriptor(
    type: 'spacer',
    label: 'Spacer',
    iconName: 'spacer',
    category: WidgetCategories.layout,
    slot: SlotKind.none,
    fields: [
      PropField(
        key: 'flex',
        kind: FieldKind.intNum,
        label: 'Flex',
        group: FieldGroups.layout,
        defaultValue: 1,
      ),
    ],
  ),
});

/// Descriptor de um primitivo, ou `null` se o tipo é desconhecido.
WidgetDescriptor? descriptorFor(String type) => widgetCatalog[type];

/// Cria um nó do primitivo [type] com as props pré-preenchidas pelos defaults
/// do catálogo. O [id] vem de quem chama (o editor gera os ids).
SduiNode defaultNode(String type, {required String id}) {
  final descriptor = widgetCatalog[type];
  if (descriptor == null) {
    throw ArgumentError.value(type, 'type', 'tipo fora do catálogo');
  }
  final defaults = <String, dynamic>{
    for (final field in descriptor.fields)
      if (field.defaultValue != null) field.key: field.defaultValue,
  };
  return SduiNode(id: id, type: type, properties: defaults);
}
