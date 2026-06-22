import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Integração ponta a ponta: o fixture `primary_button` (definido e validado no
/// kernel M0) é renderizado pelo M1 com os bindings resolvidos.
void main() {
  testWidgets('primary_button renderiza o label resolvido', (tester) async {
    final spec = jsonDecode(
      File('../../packages/spec/fixtures/widgets/primary_button.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final tree = spec['tree'] as Map<String, dynamic>;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SduiView.fromJson(
            tree,
            data: {
              'label': 'Comprar',
              'bgColor': '#1565C0',
              'productId': '42',
            },
          ),
        ),
      ),
    );

    expect(find.text('Comprar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
