import 'package:sdui_flutter/src/builders/button.dart';
import 'package:sdui_flutter/src/builders/card.dart';
import 'package:sdui_flutter/src/builders/center.dart';
import 'package:sdui_flutter/src/builders/checkbox.dart';
import 'package:sdui_flutter/src/builders/column.dart';
import 'package:sdui_flutter/src/builders/container.dart';
import 'package:sdui_flutter/src/builders/divider.dart';
import 'package:sdui_flutter/src/builders/icon.dart';
import 'package:sdui_flutter/src/builders/image.dart';
import 'package:sdui_flutter/src/builders/padding.dart';
import 'package:sdui_flutter/src/builders/row.dart';
import 'package:sdui_flutter/src/builders/sized_box.dart';
import 'package:sdui_flutter/src/builders/spacer.dart';
import 'package:sdui_flutter/src/builders/stack.dart';
import 'package:sdui_flutter/src/builders/switch.dart';
import 'package:sdui_flutter/src/builders/text.dart';
import 'package:sdui_flutter/src/builders/text_field.dart';
import 'package:sdui_flutter/src/registry.dart';

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

final SduiRegistry defaultRegistry = buildDefaultRegistry();
