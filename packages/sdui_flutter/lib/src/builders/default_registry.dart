import '../registry.dart';
import 'button.dart';
import 'card.dart';
import 'center.dart';
import 'checkbox.dart';
import 'column.dart';
import 'container.dart';
import 'divider.dart';
import 'icon.dart';
import 'image.dart';
import 'padding.dart';
import 'row.dart';
import 'sized_box.dart';
import 'spacer.dart';
import 'stack.dart';
import 'switch.dart';
import 'text.dart';
import 'text_field.dart';

/// Monta o registry padrão com os builders dos primitivos do catálogo.
/// Adicionar um primitivo = um arquivo em `builders/` + uma entrada aqui
/// (+ descriptor no catálogo do `sdui_core` — o teste de contrato cobra).
SduiRegistry buildDefaultRegistry() => SduiRegistry({
  'container': buildContainer,
  'column': buildColumn,
  'row': buildRow,
  'stack': buildStack,
  'text': buildText,
  'image': buildImage,
  'icon': buildIcon,
  'button': buildButton,
  'textField': buildTextField,
  'switch': buildSwitch,
  'checkbox': buildCheckbox,
  'card': buildCard,
  'divider': buildDivider,
  'sizedBox': buildSizedBox,
  'padding': buildPadding,
  'center': buildCenter,
  'spacer': buildSpacer,
});

/// Registry padrão compartilhado (montado uma vez).
final SduiRegistry defaultRegistry = buildDefaultRegistry();
