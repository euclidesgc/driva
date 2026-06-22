import '../renderer.dart';
import 'align.dart';
import 'aspect_ratio.dart';
import 'button.dart';
import 'card.dart';
import 'center.dart';
import 'column.dart';
import 'container.dart';
import 'divider.dart';
import 'expanded.dart';
import 'flexible.dart';
import 'fractionally_sized_box.dart';
import 'gesture_detector.dart';
import 'icon.dart';
import 'image.dart';
import 'opacity.dart';
import 'padding.dart';
import 'positioned.dart';
import 'row.dart';
import 'safe_area.dart';
import 'single_child_scroll_view.dart';
import 'sized_box.dart';
import 'spacer.dart';
import 'stack.dart';
import 'text.dart';
import 'wrap.dart';

/// Monta o registry padrão com todos os builders dos primitivos.
/// Adicionar um primitivo = um arquivo em `builders/` + uma entrada aqui.
SduiRegistry buildDefaultRegistry() => SduiRegistry({
      'container': buildContainer,
      'column': buildColumn,
      'row': buildRow,
      'wrap': buildWrap,
      'stack': buildStack,
      'positioned': buildPositioned,
      'text': buildText,
      'image': buildImage,
      'icon': buildIcon,
      'button': buildButton,
      'card': buildCard,
      'divider': buildDivider,
      'sizedBox': buildSizedBox,
      'padding': buildPadding,
      'center': buildCenter,
      'align': buildAlign,
      'aspectRatio': buildAspectRatio,
      'fractionallySizedBox': buildFractionallySizedBox,
      'opacity': buildOpacity,
      'safeArea': buildSafeArea,
      'singleChildScrollView': buildSingleChildScrollView,
      'expanded': buildExpanded,
      'flexible': buildFlexible,
      'spacer': buildSpacer,
      'gestureDetector': buildGestureDetector,
    });

/// Registry padrão compartilhado (montado uma vez).
final SduiRegistry defaultRegistry = buildDefaultRegistry();
