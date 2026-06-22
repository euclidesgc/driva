import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Text — spec §2.5.
Widget buildText(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Text(
    (p['data'] ?? '').toString(),
    style: parseTextStyle(p['style']),
    textAlign: textAlignFrom(p['textAlign']),
    maxLines: (p['maxLines'] as num?)?.toInt(),
    overflow: textOverflowFrom(p['overflow']),
    softWrap: p['softWrap'] as bool? ?? true,
  );
}
