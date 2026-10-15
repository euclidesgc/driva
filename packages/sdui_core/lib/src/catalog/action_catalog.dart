import 'package:sdui_core/src/catalog/action_descriptor.dart';
import 'package:sdui_core/src/catalog/binding_context.dart';
import 'package:sdui_core/src/catalog/field_kind.dart';
import 'package:sdui_core/src/catalog/prop_field.dart';
import 'package:sdui_core/src/catalog/prop_option.dart';

const List<ActionDescriptor> actionCatalog = [
  ActionDescriptor(
    type: 'navigate',
    label: 'Navegar para conteúdo',
    iconName: 'actionNavigate',
    category: ActionCategories.navigation,
    params: [
      PropField(
        key: 'slug',
        kind: FieldKind.string,
        label: 'Conteúdo (slug)',
        group: FieldGroups.content,
        isRequired: true,
      ),
    ],
  ),
  ActionDescriptor(
    type: 'navigateBack',
    label: 'Voltar',
    iconName: 'actionNavigateBack',
    category: ActionCategories.navigation,
  ),
  ActionDescriptor(
    type: 'launchUrl',
    label: 'Abrir link',
    iconName: 'actionLaunchUrl',
    category: ActionCategories.navigation,
    params: [
      PropField(
        key: 'url',
        kind: FieldKind.string,
        label: 'Endereço (URL)',
        group: FieldGroups.content,
        isRequired: true,
      ),
    ],
  ),
  ActionDescriptor(
    type: 'showSnackBar',
    label: 'Mostrar aviso',
    iconName: 'actionShowSnackBar',
    category: ActionCategories.alerts,
    params: [
      PropField(
        key: 'message',
        kind: FieldKind.string,
        label: 'Mensagem',
        group: FieldGroups.content,
        isRequired: true,
      ),
      PropField(
        key: 'durationMs',
        kind: FieldKind.intNum,
        label: 'Duração (ms)',
        group: FieldGroups.content,
        min: 0,
        defaultValue: 4000,
      ),
      PropField(
        key: 'backgroundColor',
        kind: FieldKind.color,
        label: 'Cor de fundo',
        group: FieldGroups.style,
      ),
    ],
  ),
  ActionDescriptor(
    type: 'copyToClipboard',
    label: 'Copiar texto',
    iconName: 'actionCopyToClipboard',
    category: ActionCategories.utilities,
    params: [
      PropField(
        key: 'text',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
        isRequired: true,
      ),
    ],
  ),
  ActionDescriptor(
    type: 'wait',
    label: 'Aguardar',
    iconName: 'actionWait',
    category: ActionCategories.utilities,
    params: [
      PropField(
        key: 'durationMs',
        kind: FieldKind.intNum,
        label: 'Duração (ms)',
        group: FieldGroups.content,
        min: 0,
        isRequired: true,
      ),
    ],
  ),
  ActionDescriptor(
    type: 'apiCall',
    label: 'Chamar API',
    iconName: 'actionApiCall',
    category: ActionCategories.backend,
    params: [
      PropField(
        key: 'url',
        kind: FieldKind.string,
        label: 'Endereço (URL)',
        group: FieldGroups.content,
        isRequired: true,
      ),
      PropField(
        key: 'method',
        kind: FieldKind.enumeration,
        label: 'Método',
        group: FieldGroups.content,
        options: [
          PropOption('GET'),
          PropOption('POST'),
          PropOption('PUT'),
          PropOption('PATCH'),
          PropOption('DELETE'),
        ],
        defaultValue: 'GET',
        isBindable: false,
      ),
    ],
  ),
];

ActionDescriptor? actionFor(
  String type, {
  Iterable<ActionDescriptor> actions = actionCatalog,
}) {
  for (final action in actions) {
    if (action.type == type) return action;
  }
  return null;
}

List<ActionDescriptor> actionsFor(
  BindingContext context, {
  Iterable<ActionDescriptor> actions = actionCatalog,
}) => [
  for (final category in ActionCategories.inPickerOrder)
    for (final action in actions)
      if (action.category == category && action.isAvailableIn(context)) action,
];
