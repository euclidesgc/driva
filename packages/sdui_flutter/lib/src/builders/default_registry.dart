import '../registry.dart';
import 'button.dart';
import 'card.dart';
import 'center.dart';
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
import 'text.dart';

/// Monta o registry padrão com os builders dos 14 primitivos do I1.
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
      'card': buildCard,
      'divider': buildDivider,
      'sizedBox': buildSizedBox,
      'padding': buildPadding,
      'center': buildCenter,
      'spacer': buildSpacer,
    });

/// Registry padrão compartilhado (montado uma vez).
final SduiRegistry defaultRegistry = buildDefaultRegistry();
