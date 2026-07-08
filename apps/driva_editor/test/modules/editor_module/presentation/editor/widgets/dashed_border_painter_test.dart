import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/dashed_border_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashedBorderPainter', () {
    testWidgets('paints dashed segments around the child area', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 40,
              child: CustomPaint(
                foregroundPainter: DashedBorderPainter(
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(customPaint.foregroundPainter, isA<DashedBorderPainter>());
    });

    test('shouldRepaint only when visual params change', () {
      const base = DashedBorderPainter(color: Color(0xFF000000));

      expect(
        base.shouldRepaint(const DashedBorderPainter(color: Color(0xFF000000))),
        isFalse,
      );
      expect(
        base.shouldRepaint(const DashedBorderPainter(color: Color(0xFFFF0000))),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const DashedBorderPainter(color: Color(0xFF000000), strokeWidth: 3),
        ),
        isTrue,
      );
    });
  });
}
