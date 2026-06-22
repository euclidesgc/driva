import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';

void main() {
  testWidgets('resolveDimension: px fixo, infinity e % de tela', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolveDimension(ctx, 120), 120.0);
    expect(resolveDimension(ctx, const {'unit': 'infinity'}), double.infinity);
    expect(
      resolveDimension(ctx, const {'unit': 'screenWidth', 'factor': 0.5}),
      200.0,
    );
    expect(
      resolveDimension(ctx, const {'unit': 'screenHeight', 'factor': 0.25}),
      200.0,
    );
    expect(resolveDimension(ctx, null), isNull);
    expect(resolveDimension(ctx, const {'unit': 'bogus'}), isNull);
  });
}
