import 'package:driva_editor/core/theme/action_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  group('ActionIcons', () {
    test('todo iconName do actionCatalog resolve', () {
      for (final action in actionCatalog) {
        expect(
          ActionIcons.resolve(action.iconName),
          isNotNull,
          reason: action.type,
        );
      }
    });

    test('nome ausente ou desconhecido resolve para null', () {
      expect(ActionIcons.resolve(null), isNull);
      expect(ActionIcons.resolve('desconhecido'), isNull);
    });
  });
}
