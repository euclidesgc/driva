import 'dart:convert';
import 'dart:io';

import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _fixture() {
  final local = File('test/fixtures/content_dimension_limits.json');
  final file = local.existsSync()
      ? local
      : File('packages/sdui_core/test/fixtures/content_dimension_limits.json');
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
}

Map<String, dynamic> _box(Map<String, dynamic> props) => {
  'id': 'n1',
  'type': 'container',
  'props': props,
};

void main() {
  group('limites min/max de dimensão', () {
    test('fixture com min/max é aceita por parseContentSpec', () {
      final result = parseContentSpec(_fixture());
      expect(result.isRight(), isTrue, reason: result.toString());
    });

    test('minWidth maior que maxWidth em px reprova com mensagem clara', () {
      final result = parseNode(_box({'minWidth': 200, 'maxWidth': 100}));
      final error = result.getLeft().toNullable();
      expect(error, isA<SpecValidationError>());
      expect(error!.message, contains('minWidth'));
      expect(error.message, contains('maxWidth'));
    });

    test('minHeight maior que maxHeight em px reprova', () {
      final result = parseNode(_box({'minHeight': 50, 'maxHeight': 10}));
      expect(result.isLeft(), isTrue);
    });

    test('percentual e inf não são comparados', () {
      expect(
        parseNode(_box({'minWidth': '80%', 'maxWidth': 10})).isRight(),
        isTrue,
      );
      expect(
        parseNode(_box({'minWidth': 500, 'maxWidth': 'inf'})).isRight(),
        isTrue,
      );
    });
  });
}
