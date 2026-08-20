import 'package:driva_editor/core/widgets/layout/fit_or_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(double width) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: 60,
        child: FitOrFallback(
          fallback: const SizedBox(width: 50, height: 40, child: Text('curto')),
          child: const SizedBox(width: 300, height: 40, child: Text('longo')),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('com espaço de sobra, escolhe o preferido', (tester) async {
    await tester.pumpWidget(_harness(400));
    await tester.pump();

    expect(find.text('longo').hitTestable(), findsOneWidget);
    expect(find.text('curto').hitTestable(), findsNothing);
  });

  testWidgets('sem espaço, cai no fallback', (tester) async {
    await tester.pumpWidget(_harness(100));
    await tester.pump();

    expect(find.text('curto').hitTestable(), findsOneWidget);
    expect(find.text('longo').hitTestable(), findsNothing);
  });

  testWidgets('a troca acompanha a largura, sem limiar fixo', (tester) async {
    await tester.pumpWidget(_harness(320));
    await tester.pump();
    expect(find.text('longo').hitTestable(), findsOneWidget);

    await tester.pumpWidget(_harness(280));
    await tester.pump();
    expect(
      find.text('curto').hitTestable(),
      findsOneWidget,
      reason: '280 < 300: o preferido deixou de caber e o fallback assume',
    );
  });
}
