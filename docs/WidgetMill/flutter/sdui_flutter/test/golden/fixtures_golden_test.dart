import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Paridade Zod↔Dart: renderiza os MESMOS fixtures que o `@widgetmill/spec`
/// valida (packages/spec/fixtures/nodes). Divergência => um dos lados quebra.
void main() {
  final dir = Directory('../../packages/spec/fixtures/nodes');
  final files = dir.existsSync()
      ? (dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  test('encontra os fixtures golden compartilhados', () {
    expect(files, isNotEmpty, reason: 'esperado packages/spec/fixtures/nodes/*.json');
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    testWidgets('renderiza $name sem exceção', (tester) async {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SduiView.fromJson(json))),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
