import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/src/model/sdui_node.dart';

void main() {
  test('fromJson lê type/props/child/children recursivamente', () {
    final node = SduiNode.fromJson({
      'type': 'container',
      'props': {'color': '#FFFFFF'},
      'child': {
        'type': 'column',
        'children': [
          {
            'type': 'text',
            'props': {'data': 'Olá'},
          },
        ],
      },
    });

    expect(node.type, 'container');
    expect(node.props['color'], '#FFFFFF');
    expect(node.child!.type, 'column');
    expect(node.child!.children.single.type, 'text');
    expect(node.child!.children.single.props['data'], 'Olá');
  });

  test('defaults: props/children vazios e child nulo', () {
    final node = SduiNode.fromJson({'type': 'spacer'});
    expect(node.props, isEmpty);
    expect(node.children, isEmpty);
    expect(node.child, isNull);
  });
}
