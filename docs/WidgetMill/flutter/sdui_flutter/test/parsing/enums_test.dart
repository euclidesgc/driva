import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/src/parsing/enums.dart';

void main() {
  test('mainAxisAlignment com default start', () {
    expect(mainAxisAlignmentFrom('spaceBetween'), MainAxisAlignment.spaceBetween);
    expect(mainAxisAlignmentFrom(null), MainAxisAlignment.start);
  });

  test('crossAxisAlignment com default center', () {
    expect(crossAxisAlignmentFrom('stretch'), CrossAxisAlignment.stretch);
    expect(crossAxisAlignmentFrom(null), CrossAxisAlignment.center);
  });

  test('textAlign com default start', () {
    expect(textAlignFrom('center'), TextAlign.center);
    expect(textAlignFrom(null), TextAlign.start);
  });

  test('textOverflow com default clip', () {
    expect(textOverflowFrom('ellipsis'), TextOverflow.ellipsis);
    expect(textOverflowFrom(null), TextOverflow.clip);
  });
}
